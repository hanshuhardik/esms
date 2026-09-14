import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../models/supplier_model.dart';
import '../providers/supplier_provider.dart';
import '../repositories/supplier_repository.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  bool? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupplierModel> _filtered(List<SupplierModel> suppliers) {
    return SupplierRepository.filterSuppliers(
      suppliers,
      searchQuery: _searchController.text,
      active: _activeFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.supplierAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add supplier'),
      ),
      body: suppliersAsync.when(
        loading: () => const LoadingWidget(message: 'Loading suppliers...'),
        error: (error, _) => _ErrorState(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(suppliersProvider),
        ),
        data: (suppliers) {
          final filtered = _filtered(suppliers);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(suppliersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PrimarySearchBar(
                  controller: _searchController,
                  hintText: 'Search suppliers...',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _FilterBar(
                  activeFilter: _activeFilter,
                  onChanged: (value) => setState(() => _activeFilter = value),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No suppliers found',
                    subtitle: 'Add a supplier or adjust your filters.',
                  )
                else
                  ...filtered.map(
                    (supplier) => _SupplierTile(supplier: supplier),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final bool? activeFilter;
  final ValueChanged<bool?> onChanged;

  const _FilterBar({required this.activeFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: activeFilter == null,
          onSelected: (_) => onChanged(null),
        ),
        ChoiceChip(
          label: const Text('Active'),
          selected: activeFilter == true,
          onSelected: (_) => onChanged(true),
        ),
        ChoiceChip(
          label: const Text('Inactive'),
          selected: activeFilter == false,
          onSelected: (_) => onChanged(false),
        ),
      ],
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final SupplierModel supplier;

  const _SupplierTile({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final statusColor = supplier.isActive ? Colors.green : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            supplier.name.isEmpty ? '?' : supplier.name[0].toUpperCase(),
          ),
        ),
        title: Text(supplier.name),
        subtitle: Text(
          [
            if (supplier.phone.isNotEmpty) supplier.phone,
            if (supplier.email.isNotEmpty) supplier.email,
            if (supplier.gstNumber.isNotEmpty) 'GSTIN: ${supplier.gstNumber}',
          ].join(' • '),
        ),
        trailing: Chip(
          label: Text(supplier.isActive ? 'Active' : 'Inactive'),
          labelStyle: TextStyle(color: statusColor),
          side: BorderSide(color: statusColor),
        ),
        onTap: () => context.push(AppRoutes.supplierDetails(supplier.id)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
