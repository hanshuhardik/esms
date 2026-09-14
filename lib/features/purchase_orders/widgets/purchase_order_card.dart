import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrderModel order;
  final VoidCallback onTap;

  const PurchaseOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (order.status) {
      PurchaseOrderStatus.draft => Colors.grey,
      PurchaseOrderStatus.ordered => Colors.blue,
      PurchaseOrderStatus.partiallyReceived => Colors.orange,
      PurchaseOrderStatus.completed => Colors.green,
      PurchaseOrderStatus.cancelled => theme.colorScheme.error,
    };

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
                          order.orderNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.supplierName.isEmpty
                              ? 'Supplier not set'
                              : order.supplierName,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(order.status.label),
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppFormatters.currency(order.grandTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Items', value: '${order.items.length}'),
              _InfoRow(
                label: 'Quantity',
                value:
                    '${order.totalReceivedQuantity}/${order.totalOrderedQuantity}',
              ),
              _InfoRow(
                label: 'Remaining',
                value: '${order.totalRemainingQuantity}',
              ),
              _InfoRow(
                label: 'Created',
                value: AppFormatters.dateTime(order.createdAt),
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
