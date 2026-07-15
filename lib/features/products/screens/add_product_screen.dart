import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/product_provider.dart';
import '../widgets/product_form.dart';

class AddProductScreen extends ConsumerWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SafeArea(
        child: ProductForm(
          saveLabel: 'Save Product',
          onSave: notifier.addProduct,
          onSaved: () {
            context.pop();
          },
        ),
      ),
    );
  }
}
