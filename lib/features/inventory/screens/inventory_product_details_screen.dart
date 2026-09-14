import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../master/providers/master_provider.dart';
import '../../products/models/product_model.dart';
import '../providers/inventory_provider.dart';
import '../utils/product_master_lookup.dart';

class InventoryProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const InventoryProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<InventoryProductDetailsScreen> createState() =>
      _InventoryProductDetailsScreenState();
}

class _InventoryProductDetailsScreenState
    extends ConsumerState<InventoryProductDetailsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
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
    final productAsync = ref.watch(inventoryProductProvider(widget.productId));
    final historyAsync = ref.watch(inventoryHistoryProvider(widget.productId));
    final brandState = ref.watch(masterProvider(FirestoreCollections.brands));
    final categoryState = ref.watch(
      masterProvider(FirestoreCollections.categories),
    );
    final locationState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Product Stock Details')),
      body: productAsync.when(
        loading: () => const LoadingWidget(message: 'Loading stock details...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load product',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (product) {
          final brandName = resolveMasterName(
            brandState.items,
            product.brandId,
          );
          final categoryName = resolveMasterName(
            categoryState.items,
            product.categoryId,
          );
          final locationName = resolveMasterName(
            locationState.items,
            product.locationId,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                product: product,
                brandName: brandName,
                categoryName: categoryName,
                locationName: locationName,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'General Information',
                children: [
                  _InfoRow(label: 'Product Name', value: product.name),
                  _InfoRow(
                    label: 'SKU',
                    value: product.sku.isEmpty ? 'Not set' : product.sku,
                  ),
                  _InfoRow(label: 'Brand', value: brandName),
                  _InfoRow(label: 'Category', value: categoryName),
                  _InfoRow(label: 'Location', value: locationName),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Inventory',
                children: [
                  _InfoRow(
                    label: 'Current Stock',
                    value: product.stockQuantity.toString(),
                  ),
                  _InfoRow(
                    label: 'Minimum Stock',
                    value: product.minimumStock.toString(),
                  ),
                  _InfoRow(
                    label: 'Stock Status',
                    value: product.isOutOfStock
                        ? 'Out Of Stock'
                        : product.isLowStock
                        ? 'Low Stock'
                        : 'In Stock',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Quick Actions',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              AppRoutes.inventoryIncrease(product.id),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Increase'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              AppRoutes.inventoryDecrease(product.id),
                            );
                          },
                          icon: const Icon(Icons.remove),
                          label: const Text('Decrease'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.inventoryAdjust(product.id));
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Manual Adjustment'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          AppRoutes.inventoryStockHistory(product.id),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Stock History'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Recent History',
                children: [
                  historyAsync.when(
                    loading: () =>
                        const LoadingWidget(message: 'Loading history...'),
                    error: (error, _) => Text(error.toString()),
                    data: (history) {
                      if (history.isEmpty) {
                        return const EmptyState(
                          icon: Icons.history,
                          title: 'No stock history yet',
                          subtitle: 'Stock changes will appear here.',
                        );
                      }

                      final recent = history.take(3).toList();

                      return Column(
                        children: recent
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _HistoryPreviewTile(entry: entry),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Pricing Snapshot',
                children: [
                  _InfoRow(
                    label: 'Purchase Price',
                    value: AppFormatters.currency(product.purchasePrice),
                  ),
                  _InfoRow(
                    label: 'Selling Price',
                    value: AppFormatters.currency(product.sellingPrice),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ProductModel product;
  final String brandName;
  final String categoryName;
  final String locationName;

  const _HeaderCard({
    required this.product,
    required this.brandName,
    required this.categoryName,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = product.isOutOfStock
        ? Theme.of(context).colorScheme.error
        : product.isLowStock
        ? Colors.orange.shade700
        : Colors.green.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(brandName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.stockQuantity} ${product.unit.label}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    product.isOutOfStock
                        ? 'Out Of Stock'
                        : product.isLowStock
                        ? 'Low Stock'
                        : 'In Stock',
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Category: $categoryName'),
            Text('Location: $locationName'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPreviewTile extends StatelessWidget {
  final ActivityLogModel entry;

  const _HistoryPreviewTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final differenceColor = entry.difference >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.reason,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${entry.difference >= 0 ? '+' : ''}${entry.difference}',
                style: TextStyle(
                  color: differenceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${entry.previousStock} -> ${entry.newStock}'),
          const SizedBox(height: 4),
          Text(
            '${entry.staffName} • ${AppFormatters.dateTime(entry.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
