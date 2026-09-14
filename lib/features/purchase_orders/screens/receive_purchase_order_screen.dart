import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_order_provider.dart';

class ReceivePurchaseOrderScreen extends ConsumerWidget {
  final String orderId;

  const ReceivePurchaseOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseOrderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Purchase Order')),
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
          if (!order.canReceive) {
            return EmptyState(
              icon: Icons.block_outlined,
              title: 'Order cannot be received',
              subtitle: 'This order is already completed or cancelled.',
            );
          }

          return _ReceiveForm(order: order);
        },
      ),
    );
  }
}

class _ReceiveForm extends ConsumerStatefulWidget {
  final PurchaseOrderModel order;

  const _ReceiveForm({required this.order});

  @override
  ConsumerState<_ReceiveForm> createState() => _ReceiveFormState();
}

class _ReceiveFormState extends ConsumerState<_ReceiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<_ReceiveDraftItem> _items = [];

  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.order.items.map(_ReceiveDraftItem.fromModel));
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int _readInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final receivedQuantities = <String, int>{};
    var totalReceived = 0;

    for (final item in _items) {
      final requested = _readInt(item.receiveController);
      final clamped = requested.clamp(0, item.remainingQuantity).toInt();
      receivedQuantities[item.id] = clamped;
      totalReceived += clamped;
    }

    if (totalReceived <= 0) {
      setState(() {
        _errorText = 'Enter at least one received quantity.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final errorMessage = await ref
        .read(purchaseOrderProvider.notifier)
        .receiveOrder(
          orderId: widget.order.id,
          receivedQuantities: receivedQuantities,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      context.pop();
      return;
    }

    setState(() {
      _saving = false;
      _errorText = errorMessage;
    });
  }

  Widget _buildItemCard(_ReceiveDraftItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Ordered: ${item.quantityOrdered}'),
            Text('Already Received: ${item.quantityReceived}'),
            Text('Remaining: ${item.remainingQuantity}'),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: item.receiveController,
              labelText: 'Receive Quantity',
              keyboardType: TextInputType.number,
              validator: (value) {
                final quantity = int.tryParse(value?.trim() ?? '');
                if (quantity == null || quantity < 0) {
                  return 'Enter a valid quantity';
                }

                if (quantity > item.remainingQuantity) {
                  return 'Cannot exceed remaining quantity';
                }

                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Line Total: ${AppFormatters.currency(item.lineTotal)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingCount = widget.order.totalRemainingQuantity;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.order.orderNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.order.supplierName),
                  const SizedBox(height: 8),
                  Text('Remaining Items: $remainingCount'),
                  const SizedBox(height: 4),
                  Text(
                    'Grand Total: ${AppFormatters.currency(widget.order.grandTotal)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map(_buildItemCard),
          const SizedBox(height: 16),
          PrimaryTextField(
            controller: _notesController,
            labelText: 'Receiving Notes (Optional)',
            maxLines: 4,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Confirm Receipt',
            onPressed: _saving ? null : _submit,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _ReceiveDraftItem {
  final String id;
  final String productName;
  final int quantityOrdered;
  final int quantityReceived;
  final int remainingQuantity;
  final double lineTotal;
  final TextEditingController receiveController;

  _ReceiveDraftItem({
    required this.id,
    required this.productName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.remainingQuantity,
    required this.lineTotal,
    required this.receiveController,
  });

  factory _ReceiveDraftItem.fromModel(PurchaseOrderItemModel item) {
    return _ReceiveDraftItem(
      id: item.id,
      productName: item.productName,
      quantityOrdered: item.quantityOrdered,
      quantityReceived: item.quantityReceived,
      remainingQuantity: item.remainingQuantity,
      lineTotal: item.lineTotal,
      receiveController: TextEditingController(
        text: item.remainingQuantity.toString(),
      ),
    );
  }

  void dispose() {
    receiveController.dispose();
  }
}
