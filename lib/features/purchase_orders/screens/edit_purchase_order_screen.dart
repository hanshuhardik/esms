import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/purchase_order_provider.dart';
import '../widgets/purchase_order_form.dart';

class EditPurchaseOrderScreen extends ConsumerWidget {
  final String orderId;

  const EditPurchaseOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseOrderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Purchase Order')),
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
          return PurchaseOrderForm(
            saveLabel: 'Update Purchase Order',
            initialOrder: order,
            onSave: (updatedOrder) {
              return ref
                  .read(purchaseOrderProvider.notifier)
                  .updateOrder(updatedOrder);
            },
            onSaved: () => context.pop(),
          );
        },
      ),
    );
  }
}
