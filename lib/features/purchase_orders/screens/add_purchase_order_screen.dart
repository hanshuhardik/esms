import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/purchase_order_provider.dart';
import '../widgets/purchase_order_form.dart';

class AddPurchaseOrderScreen extends ConsumerWidget {
  const AddPurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Order')),
      body: PurchaseOrderForm(
        saveLabel: 'Save Purchase Order',
        onSave: (order) {
          return ref.read(purchaseOrderProvider.notifier).addOrder(order);
        },
        onSaved: () => context.pop(),
      ),
    );
  }
}
