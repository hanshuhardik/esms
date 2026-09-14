import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/billing/models/bill_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/return_model.dart';
import '../providers/return_provider.dart';
import 'return_details_screen.dart';

class ReturnFormScreen extends ConsumerStatefulWidget {
  final BillModel bill;

  const ReturnFormScreen({required this.bill, super.key});

  @override
  ConsumerState<ReturnFormScreen> createState() => _ReturnFormScreenState();
}

class _ReturnFormScreenState extends ConsumerState<ReturnFormScreen> {
  final _selectedQuantities = <String, int>{};
  String? _searchError;

  Future<void> _processReturn(List<ReturnModel> previousReturns) async {
    if (AuthService.currentUser == null) {
      setState(
        () => _searchError = 'User must be signed in to process a return.',
      );
      return;
    }

    final items = _buildSelectedItems();
    if (items.isEmpty) {
      setState(() => _searchError = 'Please select at least one product.');
      return;
    }

    final subtotal = _subtotal(items);
    final discount = _applicableDiscount(previousReturns);
    final refund = (subtotal - discount).clamp(0.0, subtotal).toDouble();
    final confirmed = await _confirmReturn(items, subtotal, discount, refund);
    if (!confirmed || !mounted) return;

    final created = await ref
        .read(returnNotifierProvider.notifier)
        .create(
          customerPhone: widget.bill.customerPhone ?? '',
          customerName: widget.bill.customerName,
          items: items,
        );
    if (!mounted) return;

    final state = ref.read(returnNotifierProvider);
    if (created == null) {
      setState(
        () => _searchError = state.errorMessage ?? 'Failed to process return.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return processed successfully.')),
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReturnDetailsScreen(returnModel: created),
      ),
    );
  }

  List<ReturnItem> _buildSelectedItems() {
    final items = <ReturnItem>[];
    for (var index = 0; index < widget.bill.items.length; index++) {
      final billItem = widget.bill.items[index];
      final key = _sourceKey(widget.bill.id, index);
      final quantity = _selectedQuantities[key] ?? 0;
      if (quantity <= 0) continue;
      items.add(
        ReturnItem(
          originalBillId: widget.bill.id,
          originalItemIndex: index,
          productId: billItem.productId,
          productName: billItem.productName,
          quantity: quantity,
          unitPrice: billItem.sellingPrice,
          total: quantity * billItem.sellingPrice,
        ),
      );
    }
    return items;
  }

  int _alreadyReturned(
    List<ReturnModel> previousReturns,
    String billId,
    int itemIndex,
  ) {
    return previousReturns.fold<int>(0, (total, previous) {
      return total +
          previous.items
              .where(
                (item) =>
                    item.originalBillId == billId &&
                    item.originalItemIndex == itemIndex,
              )
              .fold<int>(0, (sum, item) => sum + item.quantity);
    });
  }

  double _applicableDiscount(List<ReturnModel> previousReturns) {
    var consumed = 0.0;
    for (final previous in previousReturns) {
      if (previous.discountAllocations.isNotEmpty) {
        consumed += previous.discountAllocations[widget.bill.id] ?? 0.0;
      } else if (previous.discount > 0 &&
          previous.originalBillIds.contains(widget.bill.id)) {
        consumed = double.infinity;
      }
    }

    if (consumed.isInfinite) return 0.0;
    return (widget.bill.discount - consumed)
        .clamp(0.0, widget.bill.discount)
        .toDouble();
  }

  double _subtotal(List<ReturnItem> items) {
    return items.fold<double>(0.0, (total, item) => total + item.total);
  }

  Future<bool> _confirmReturn(
    List<ReturnItem> items,
    double subtotal,
    double discount,
    double refund,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm return'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${item.productName} × ${item.quantity} = ${AppFormatters.currency(item.total)}',
                      ),
                    ),
                  ),
                  const Divider(),
                  Text('Subtotal: ${AppFormatters.currency(subtotal)}'),
                  Text('Discount: ${AppFormatters.currency(discount)}'),
                  Text('Refund: ${AppFormatters.currency(refund)}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _sourceKey(String billId, int itemIndex) => '$billId#$itemIndex';

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(customerReturnsProvider(widget.bill.id));
    final previousReturns = returnsAsync.valueOrNull ?? const <ReturnModel>[];
    final isCreating = ref.watch(returnNotifierProvider).isCreating;

    return Scaffold(
      appBar: AppBar(title: const Text('Return Item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            Text(_searchError!, style: TextStyle(color: Colors.red[700])),
          ],
          if (returnsAsync.isLoading) ...[
            const SizedBox(height: 32),
            const LoadingWidget(message: 'Loading previous returns...'),
          ] else ...[
            const SizedBox(height: 20),
            _BillCard(
              bill: widget.bill,
              previousReturns: previousReturns,
              selectedQuantities: _selectedQuantities,
              sourceKey: _sourceKey,
              alreadyReturned: _alreadyReturned,
              onQuantityChanged: (key, value) =>
                  setState(() => _selectedQuantities[key] = value),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              items: _buildSelectedItems(),
              discount: _applicableDiscount(previousReturns),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Process return',
              isLoading: isCreating,
              onPressed: isCreating
                  ? null
                  : () => _processReturn(previousReturns),
            ),
          ],
          if (returnsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Unable to load previous returns. Reload this bill and try again.',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final List<ReturnModel> previousReturns;
  final Map<String, int> selectedQuantities;
  final String Function(String, int) sourceKey;
  final int Function(List<ReturnModel>, String, int) alreadyReturned;
  final void Function(String, int) onQuantityChanged;

  const _BillCard({
    required this.bill,
    required this.previousReturns,
    required this.selectedQuantities,
    required this.sourceKey,
    required this.alreadyReturned,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bill.billNumber,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Date: ${AppFormatters.date(bill.createdAt)}'),
            Text('Total: ${AppFormatters.currency(bill.total)}'),
            Text('Discount: ${AppFormatters.currency(bill.discount)}'),
            if (bill.customerName?.isNotEmpty == true)
              Text('Customer: ${bill.customerName}'),
            const Divider(),
            ...bill.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final returned = alreadyReturned(previousReturns, bill.id, index);
              final remaining = (item.quantity - returned).clamp(
                0,
                item.quantity,
              );
              final key = sourceKey(bill.id, index);
              final selected = selectedQuantities[key] ?? 0;
              return _ReturnItemRow(
                item: item,
                returned: returned,
                remaining: remaining,
                selected: selected,
                onChanged: (value) => onQuantityChanged(key, value),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ReturnItemRow extends StatelessWidget {
  final BillItemModel item;
  final int returned;
  final int remaining;
  final int selected;
  final ValueChanged<int> onChanged;

  const _ReturnItemRow({
    required this.item,
    required this.returned,
    required this.remaining,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName),
                Text(
                  'Original quantity: ${item.quantity} • Already returned: $returned • Remaining: $remaining',
                ),
                Text(
                  'Unit price: ${AppFormatters.currency(item.sellingPrice)}',
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: disabled || selected <= 0
                ? null
                : () => onChanged(selected - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('Quantity to return: $selected'),
          IconButton(
            onPressed: disabled || selected >= remaining
                ? null
                : () => onChanged(selected + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<ReturnItem> items;
  final double discount;

  const _SummaryCard({required this.items, required this.discount});

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.total);
    final refund = (subtotal - discount).clamp(0.0, subtotal).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Subtotal: ${AppFormatters.currency(subtotal)}'),
            Text('Discount: ${AppFormatters.currency(discount)}'),
            Text('Refund: ${AppFormatters.currency(refund)}'),
          ],
        ),
      ),
    );
  }
}
