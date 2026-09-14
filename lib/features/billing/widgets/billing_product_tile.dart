import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../products/models/product_model.dart';

class BillingProductTile extends StatelessWidget {
  final ProductModel product;
  final String displayName;
  final String locationName;
  final VoidCallback onAdd;

  const BillingProductTile({
    super.key,
    required this.product,
    required this.displayName,
    required this.locationName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSell =
        product.status == ProductStatus.active && product.stockQuantity > 0;
    final safeLocation = locationName.trim().isEmpty ? 'Not set' : locationName;

    return Card(
      child: ListTile(
        onTap: canSell ? onAdd : null,
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Location: '),
              TextSpan(
                text: safeLocation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.currency(product.sellingPrice),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text('Stock: ${product.stockQuantity}'),
          ],
        ),
      ),
    );
  }
}
