import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../products/models/product_model.dart';

class InventoryProductCard extends StatelessWidget {
  final ProductModel product;
  final String brandName;
  final String categoryName;
  final String locationName;
  final VoidCallback onTap;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.brandName,
    required this.categoryName,
    required this.locationName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockColor = product.isOutOfStock
        ? theme.colorScheme.error
        : product.isLowStock
        ? Colors.orange.shade700
        : Colors.green.shade700;

    final statusText = product.isOutOfStock
        ? 'Out Of Stock'
        : product.isLowStock
        ? 'Low Stock'
        : 'In Stock';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku.isEmpty ? 'Not set' : product.sku}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(statusText),
                    backgroundColor: stockColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: stockColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppFormatters.currency(product.sellingPrice),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Brand', value: brandName),
              _InfoRow(label: 'Category', value: categoryName),
              _InfoRow(label: 'Location', value: locationName),
              _InfoRow(
                label: 'Current Stock',
                value: '${product.stockQuantity}',
              ),
              _InfoRow(
                label: 'Minimum Stock',
                value: '${product.minimumStock}',
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
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
