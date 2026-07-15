import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../master/providers/master_provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../utils/product_master_lookup.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));
    final brandState = ref.watch(masterProvider(FirestoreCollections.brands));
    final categoryState = ref.watch(
      masterProvider(FirestoreCollections.categories),
    );
    final locationState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          productAsync.maybeWhen(
            data: (product) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                context.push(AppRoutes.productEdit(product.id));
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () =>
            const LoadingWidget(message: 'Loading product details...'),
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
              _HeaderCard(product: product, brandName: brandName),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'General Information',
                children: [
                  _InfoRow(label: 'Name', value: product.name),
                  _InfoRow(
                    label: 'SKU',
                    value: product.sku.isEmpty ? 'Not set' : product.sku,
                  ),
                  _InfoRow(label: 'Brand', value: brandName),
                  _InfoRow(label: 'Category', value: categoryName),
                  _InfoRow(label: 'Unit', value: product.unit.label),
                  _InfoRow(
                    label: 'Status',
                    value: product.status.name.toUpperCase(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Pricing',
                children: [
                  _InfoRow(
                    label: 'Purchase Price',
                    value: AppFormatters.currency(product.purchasePrice),
                  ),
                  _InfoRow(
                    label: 'Selling Price',
                    value: AppFormatters.currency(product.sellingPrice),
                  ),
                  _InfoRow(
                    label: 'Profit Amount',
                    value: AppFormatters.currency(product.profitAmount),
                  ),
                  _InfoRow(
                    label: 'Profit Percentage',
                    value: '${product.profitPercentage.toStringAsFixed(2)}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Inventory',
                children: [
                  _InfoRow(
                    label: 'Current Stock',
                    value: '${product.stockQuantity}',
                  ),
                  _InfoRow(
                    label: 'Minimum Stock',
                    value: '${product.minimumStock}',
                  ),
                  _InfoRow(label: 'Location', value: locationName),
                  _InfoRow(
                    label: 'Stock Status',
                    value: product.isOutOfStock
                        ? 'Out of Stock'
                        : product.isLowStock
                        ? 'Low Stock'
                        : 'In Stock',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Supplier',
                children: [
                  _InfoRow(
                    label: 'Supplier ID',
                    value: product.supplierId.isEmpty
                        ? 'Not set'
                        : product.supplierId,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Barcode',
                children: [
                  _InfoRow(
                    label: 'Barcode',
                    value: product.barcode?.isNotEmpty == true
                        ? product.barcode!
                        : 'Not set',
                  ),
                  _InfoRow(
                    label: 'Image URL',
                    value: product.imageUrl?.isNotEmpty == true
                        ? product.imageUrl!
                        : 'Not set',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Dates',
                children: [
                  _InfoRow(
                    label: 'Created Date',
                    value: AppFormatters.dateTime(product.createdAt),
                  ),
                  _InfoRow(
                    label: 'Updated Date',
                    value: AppFormatters.dateTime(product.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.productEdit(product.id));
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: Text('Delete "${product.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) {
                          return;
                        }

                        final errorMessage = await ref
                            .read(productProvider.notifier)
                            .deleteProduct(product.id);

                        if (!context.mounted) {
                          return;
                        }

                        if (errorMessage != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(errorMessage)));
                          return;
                        }

                        context.pop();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
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

  const _HeaderCard({required this.product, required this.brandName});

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isOutOfStock
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
                Text(
                  AppFormatters.currency(product.sellingPrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    product.isOutOfStock
                        ? 'Out of Stock'
                        : product.isLowStock
                        ? 'Low Stock'
                        : 'In Stock',
                  ),
                  backgroundColor: stockColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: stockColor),
                ),
              ],
            ),
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
