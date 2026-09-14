import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../master/providers/master_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryDashboardScreen extends ConsumerStatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  ConsumerState<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState
    extends ConsumerState<InventoryDashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(inventoryProvider.notifier).loadInventory();
      ref
          .read(masterProvider(FirestoreCollections.brands).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.categories).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.locations).notifier)
          .loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final totalItems = state.items.length;
    final lowStockItems = state.items.where((item) => item.isLowStock).length;
    final outOfStockItems = state.items
        .where((item) => item.isOutOfStock)
        .length;
    final inStockItems = state.items.where((item) => item.isInStock).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: state.isLoading && state.items.isEmpty
          ? const LoadingWidget(message: 'Loading inventory...')
          : state.errorMessage != null && state.items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load inventory',
                subtitle: state.errorMessage!,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryGrid(
                  totalItems: totalItems,
                  inStockItems: inStockItems,
                  lowStockItems: lowStockItems,
                  outOfStockItems: outOfStockItems,
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'All Inventory',
                  subtitle: 'Browse every stock item',
                  onTap: () => context.push(AppRoutes.inventoryList),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.warning_amber_outlined,
                  title: 'Low Stock',
                  subtitle: 'Items approaching reorder level',
                  onTap: () => context.push(AppRoutes.inventoryLowStock),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.remove_shopping_cart_outlined,
                  title: 'Out Of Stock',
                  subtitle: 'Items currently unavailable',
                  onTap: () => context.push(AppRoutes.inventoryOutOfStock),
                ),
              ],
            ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final int totalItems;
  final int inStockItems;
  final int lowStockItems;
  final int outOfStockItems;

  const _SummaryGrid({
    required this.totalItems,
    required this.inStockItems,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _SummaryCard(
          label: 'Total Items',
          value: '$totalItems',
          icon: Icons.inventory_2_outlined,
        ),
        _SummaryCard(
          label: 'In Stock',
          value: '$inStockItems',
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          label: 'Low Stock',
          value: '$lowStockItems',
          icon: Icons.warning_amber_outlined,
        ),
        _SummaryCard(
          label: 'Out Of Stock',
          value: '$outOfStockItems',
          icon: Icons.remove_shopping_cart_outlined,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
