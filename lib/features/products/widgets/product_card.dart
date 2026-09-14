import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/product_model.dart';
import '../utils/product_master_lookup.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String brandName;
  final String categoryName;
  final String locationName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.brandName,
    required this.categoryName,
    required this.locationName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _stockColor(ThemeData theme) {
    if (product.isOutOfStock) {
      return theme.colorScheme.error;
    }

    if (product.isLowStock) {
      return Colors.orange.shade700;
    }

    return Colors.green.shade700;
  }

  String _stockStatus() {
    if (product.isOutOfStock) {
      return 'Out of Stock';
    }

    if (product.isLowStock) {
      return 'Low Stock';
    }

    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockColor = _stockColor(theme);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatProductDisplayName(product.name, brandName),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              const TextSpan(text: 'Location: '),
                              TextSpan(
                                text: locationName.trim().isEmpty
                                    ? 'Not set'
                                    : locationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.sku.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product.sku}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    AppFormatters.currency(product.sellingPrice),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _stockStatus(),
                      style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: stockColor),
                  const SizedBox(width: 6),
                  Text(
                    '${product.stockQuantity} ${product.unit.label}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (product.isLowStock) ...[
                    Chip(
                      label: const Text('Low Stock'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(color: Colors.orange.shade900),
                    ),
                  ],
                  if (product.isOutOfStock) ...[
                    Chip(
                      label: const Text('Out of Stock'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ],
              ),

              const Divider(height: 24),

              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
