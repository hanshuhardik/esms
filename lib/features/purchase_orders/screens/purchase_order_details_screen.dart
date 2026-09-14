import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const PurchaseOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseOrderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Order Details')),
      body: orderAsync.when(
        loading: () =>
            const LoadingWidget(message: 'Loading purchase order...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load purchase order',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (order) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(order: order),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Order Information',
                children: [
                  _InfoRow(label: 'Order Number', value: order.orderNumber),
                  _InfoRow(label: 'Supplier', value: order.supplierName),
                  _InfoRow(label: 'Status', value: order.status.label),
                  _InfoRow(label: 'Created By', value: order.createdByName),
                  _InfoRow(
                    label: 'Created Date',
                    value: AppFormatters.dateTime(order.createdAt),
                  ),
                  if (order.receivedAt != null)
                    _InfoRow(
                      label: 'Received Date',
                      value: AppFormatters.dateTime(order.receivedAt!),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Items',
                children: order.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  label: 'SKU',
                                  value: item.sku.isEmpty
                                      ? 'Not set'
                                      : item.sku,
                                ),
                                _InfoRow(
                                  label: 'Ordered',
                                  value: '${item.quantityOrdered}',
                                ),
                                _InfoRow(
                                  label: 'Received',
                                  value: '${item.quantityReceived}',
                                ),
                                _InfoRow(
                                  label: 'Remaining',
                                  value: '${item.remainingQuantity}',
                                ),
                                _InfoRow(
                                  label: 'Unit Cost',
                                  value: AppFormatters.currency(item.unitCost),
                                ),
                                _InfoRow(
                                  label: 'GST %',
                                  value: item.gstPercent.toStringAsFixed(2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Totals',
                children: [
                  _InfoRow(
                    label: 'Subtotal',
                    value: AppFormatters.currency(order.subtotal),
                  ),
                  _InfoRow(
                    label: 'GST',
                    value: AppFormatters.currency(order.gstAmount),
                  ),
                  _InfoRow(
                    label: 'Grand Total',
                    value: AppFormatters.currency(order.grandTotal),
                  ),
                ],
              ),
              if ((order.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(title: 'Notes', children: [Text(order.notes!)]),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.purchaseOrderEdit(order.id)),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: order.canReceive
                          ? () => context.push(
                              AppRoutes.purchaseOrderReceive(order.id),
                            )
                          : null,
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Receive'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Purchase Order'),
                      content: Text('Delete "${order.orderNumber}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) {
                    return;
                  }

                  final errorMessage = await ref
                      .read(purchaseOrderProvider.notifier)
                      .deleteOrder(order.id);

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
                label: const Text('Delete Order'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseOrderModel order;

  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      PurchaseOrderStatus.draft => Colors.grey,
      PurchaseOrderStatus.ordered => Colors.blue,
      PurchaseOrderStatus.partiallyReceived => Colors.orange,
      PurchaseOrderStatus.completed => Colors.green,
      PurchaseOrderStatus.cancelled => Theme.of(context).colorScheme.error,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(order.status.label),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(order.supplierName),
            const SizedBox(height: 12),
            Text(
              AppFormatters.currency(order.grandTotal),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.totalReceivedQuantity}/${order.totalOrderedQuantity} items received',
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
      padding: const EdgeInsets.only(bottom: 8),
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
