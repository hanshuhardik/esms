import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/product_provider.dart';
import '../widgets/product_form.dart';

class EditProductScreen extends ConsumerWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));
    final notifier = ref.read(productProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: productAsync.when(
        loading: () => const LoadingWidget(message: 'Loading product...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load product',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (product) {
          return SafeArea(
            child: ProductForm(
              saveLabel: 'Update Product',
              initialProduct: product,
              onSave: notifier.updateProduct,
              onSaved: () {
                context.pop();
              },
            ),
          );
        },
      ),
    );
  }
}
