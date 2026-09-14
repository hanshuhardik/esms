import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/bill_model.dart';
import '../providers/billing_provider.dart';
import '../repositories/billing_repository.dart';
import '../services/bill_receipt_service.dart';

class BillDetailsScreen extends ConsumerWidget {
  final String billId;

  const BillDetailsScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(billingDetailsProvider(billId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Details')),
      body: billAsync.when(
        loading: () => const LoadingWidget(message: 'Loading bill...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load bill',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (bill) {
          final statusColor = switch (bill.status) {
            BillStatus.draft => Colors.grey,
            BillStatus.completed => Colors.green,
            BillStatus.cancelled => Theme.of(context).colorScheme.error,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bill.billNumber,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Chip(
                            label: Text(bill.status.label),
                            backgroundColor: statusColor.withValues(
                              alpha: 0.12,
                            ),
                            labelStyle: TextStyle(color: statusColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Created by: ${bill.createdBy}'),
                      Text('Date: ${AppFormatters.dateTime(bill.createdAt)}'),
                      Text('Payment: ${bill.paymentMethod.label}'),
                      if (bill.customerName?.isNotEmpty == true)
                        Text('Customer: ${bill.customerName}'),
                      if (bill.customerPhone?.isNotEmpty == true)
                        Text('Phone: ${bill.customerPhone}'),
                      Text(
                        'Taken by: ${bill.takenBy.trim().isEmpty ? 'Walk-in Customer' : bill.takenBy}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Items',
                children: bill.items
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
                                  label: 'Quantity',
                                  value: '${item.quantity}',
                                ),
                                _InfoRow(
                                  label: 'Rate',
                                  value: AppFormatters.currency(
                                    item.sellingPrice,
                                  ),
                                ),
                                _InfoRow(
                                  label: 'Discount',
                                  value: AppFormatters.currency(item.discount),
                                ),
                                _InfoRow(
                                  label: 'Amount',
                                  value: AppFormatters.currency(item.lineTotal),
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
                    value: AppFormatters.currency(bill.subtotal),
                  ),
                  _InfoRow(
                    label: 'Discount',
                    value: AppFormatters.currency(bill.discount),
                  ),
                  _InfoRow(
                    label: 'Total',
                    value: AppFormatters.currency(bill.total),
                  ),
                  _InfoRow(
                    label: 'Paid',
                    value: AppFormatters.currency(bill.amountPaid),
                  ),
                  _InfoRow(
                    label: 'Due',
                    value: AppFormatters.currency(bill.amountDue),
                  ),
                  _InfoRow(
                    label: 'Payment status',
                    value: bill.paymentStatus.label,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (bill.status == BillStatus.completed) ...[
                if (bill.amountDue > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final updated = await _showCollectDuePaymentDialog(
                          context,
                          bill,
                        );
                        if (updated != null) {
                          ref.invalidate(billingDetailsProvider(bill.id));
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Collect Due Payment'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await context.push<BillModel>(
                        AppRoutes.billEdit(bill.id),
                        extra: bill,
                      );
                      if (updated != null) {
                        ref.invalidate(billingDetailsProvider(bill.id));
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Bill'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (bill.status == BillStatus.completed) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.returns, extra: bill),
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: const Text('Return Item'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await BillReceiptService.printBill(bill);
                      },
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await BillReceiptService.shareBill(bill);
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
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

Future<BillModel?> _showCollectDuePaymentDialog(
  BuildContext context,
  BillModel bill,
) async {
  final controller = TextEditingController();
  String? errorMessage;
  var saving = false;

  final result = await showDialog<BillModel>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> collect() async {
          final amount = double.tryParse(controller.text.trim()) ?? 0;
          if (amount <= 0 || amount > bill.amountDue) {
            setState(() {
              errorMessage =
                  'Enter an amount greater than zero and no more than the outstanding due.';
            });
            return;
          }
          setState(() {
            saving = true;
            errorMessage = null;
          });
          final response = await BillingRepository.collectDuePayment(
            billId: bill.id,
            amountReceived: amount,
          );
          if (!dialogContext.mounted) return;
          if (response.isFailure || response.data == null) {
            setState(() {
              saving = false;
              errorMessage = response.error ?? 'Failed to collect payment.';
            });
            return;
          }
          Navigator.of(dialogContext).pop(response.data);
        }

        return AlertDialog(
          title: const Text('Collect Due Payment'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: ${AppFormatters.currency(bill.total)}'),
                Text(
                  'Already paid: ${AppFormatters.currency(bill.amountPaid)}',
                ),
                Text(
                  'Outstanding due: ${AppFormatters.currency(bill.amountDue)}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  enabled: !saving,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount Received',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving ? null : collect,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Collect'),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return result;
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
