import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class SupplierDetailsScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailsScreen({required this.supplierId, super.key});

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    SupplierModel supplier,
    UserModel? user,
  ) async {
    if (user == null) return;
    final updated = supplier.copyWith(isActive: !supplier.isActive);
    final error = await ref
        .read(supplierNotifierProvider.notifier)
        .update(updated, user);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (updated.isActive
                  ? 'Supplier activated'
                  : 'Supplier deactivated'),
        ),
      ),
    );
    if (error == null) ref.invalidate(supplierDetailsProvider(supplier.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierDetailsProvider(supplierId));
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Details')),
      body: supplierAsync.when(
        loading: () => const LoadingWidget(message: 'Loading supplier...'),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (supplier) {
          if (supplier == null) {
            return const Center(child: Text('Supplier not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        child: Text(
                          supplier.name.isEmpty
                              ? '?'
                              : supplier.name[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        supplier.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(supplier.isActive ? 'Active' : 'Inactive'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Contact person',
                      value: supplier.contactPerson,
                    ),
                    _InfoRow(label: 'Phone', value: supplier.phone),
                    _InfoRow(label: 'Email', value: supplier.email),
                    _InfoRow(label: 'Address', value: supplier.address),
                    _InfoRow(label: 'GSTIN', value: supplier.gstNumber),
                    _InfoRow(
                      label: 'Created',
                      value: _date(supplier.createdAt),
                    ),
                    _InfoRow(
                      label: 'Updated',
                      value: _date(supplier.updatedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.supplierEdit(supplier.id)),
                icon: const Icon(Icons.edit),
                label: const Text('Edit supplier'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _toggleStatus(context, ref, supplier, user),
                icon: Icon(supplier.isActive ? Icons.pause : Icons.play_arrow),
                label: Text(
                  supplier.isActive
                      ? 'Deactivate supplier'
                      : 'Activate supplier',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suppliers are deactivated instead of deleted so purchase-order history remains intact.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
