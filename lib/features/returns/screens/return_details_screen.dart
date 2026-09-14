import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/return_model.dart';

class ReturnDetailsScreen extends StatelessWidget {
  final ReturnModel returnModel;

  const ReturnDetailsScreen({required this.returnModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Return ID', value: returnModel.returnId),
                  _DetailRow(
                    label: 'Original bill IDs',
                    value: returnModel.originalBillIds.join(', '),
                  ),
                  _DetailRow(
                    label: 'Created',
                    value: AppFormatters.dateTime(returnModel.createdAt),
                  ),
                  _DetailRow(label: 'Created by', value: returnModel.createdBy),
                  _DetailRow(
                    label: 'Customer phone',
                    value: returnModel.customerPhone,
                  ),
                  if (returnModel.customerName?.isNotEmpty == true)
                    _DetailRow(
                      label: 'Customer name',
                      value: returnModel.customerName!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Returned items', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (returnModel.items.isEmpty)
            const EmptyState(
              icon: Icons.assignment_return_outlined,
              title: 'No returned items',
              subtitle: 'This return does not contain any item lines.',
            )
          else
            ...returnModel.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    'Bill: ${item.originalBillId}\n'
                    'Quantity: ${item.quantity}\n'
                    'Unit price: ${AppFormatters.currency(item.unitPrice)}',
                  ),
                  trailing: Text(AppFormatters.currency(item.total)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Subtotal',
                    value: AppFormatters.currency(returnModel.subtotal),
                  ),
                  _DetailRow(
                    label: 'Discount',
                    value: AppFormatters.currency(returnModel.discount),
                  ),
                  _DetailRow(
                    label: 'Refund amount',
                    value: AppFormatters.currency(returnModel.refundAmount),
                  ),
                  _DetailRow(
                    label: 'Applied to due',
                    value: AppFormatters.currency(
                      returnModel.amountAppliedToDue,
                    ),
                  ),
                  _DetailRow(
                    label: 'Cash refund',
                    value: AppFormatters.currency(returnModel.cashRefundAmount),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value.isEmpty ? 'Not available' : value)),
        ],
      ),
    );
  }
}
