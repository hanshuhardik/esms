import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../../master/providers/master_provider.dart';
import '../../products/models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../../products/utils/product_master_lookup.dart';
import '../models/bill_model.dart';
import '../providers/billing_provider.dart';
import '../widgets/billing_cart_tile.dart';
import '../widgets/billing_product_tile.dart';

class BillingPosScreen extends ConsumerStatefulWidget {
  const BillingPosScreen({super.key});

  @override
  ConsumerState<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends ConsumerState<BillingPosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _takenByController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productProvider.notifier).loadProducts();
      ref
          .read(masterProvider(FirestoreCollections.brands).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.locations).notifier)
          .loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _takenByController.dispose();
    super.dispose();
  }

  List<ProductModel> _filteredProducts(
    List<ProductModel> products,
    String query,
    List<dynamic> brandItems,
    List<dynamic> locationItems,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];

    return products
        .where((product) {
          final brandName = resolveMasterName(
            brandItems.cast(),
            product.brandId,
            fallback: '',
          );
          final locationName = resolveMasterName(
            locationItems.cast(),
            product.locationId,
            fallback: '',
          );

          final searchableBrand = brandName.toLowerCase();
          final searchableLocation = locationName.toLowerCase();

          return product.name.toLowerCase().contains(normalized) ||
              product.sku.toLowerCase().contains(normalized) ||
              (product.barcode?.toLowerCase().contains(normalized) ?? false) ||
              searchableBrand.contains(normalized) ||
              searchableLocation.contains(normalized);
        })
        .take(8)
        .toList();
  }

  void _addProduct(
    ProductModel product, {
    required String brandName,
    required String locationName,
  }) {
    final notifier = ref.read(billingProvider.notifier);
    final error = notifier.addProduct(
      product,
      brandName: brandName,
      locationName: locationName,
    );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _searchController.clear();
    notifier.updateSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final billingState = ref.watch(billingProvider);
    final brandsState = ref.watch(masterProvider(FirestoreCollections.brands));
    final locationsState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );
    final notifier = ref.read(billingProvider.notifier);
    final filteredProducts = _filteredProducts(
      productState.products,
      billingState.searchQuery,
      brandsState.items,
      locationsState.items,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Billing'),
        actions: [
          TextButton(
            onPressed: billingState.items.isEmpty
                ? null
                : () {
                    notifier.clearCart();
                    _discountController.clear();
                    _amountPaidController.clear();
                    _customerNameController.clear();
                    _customerPhoneController.clear();
                    _takenByController.clear();
                  },
            child: const Text('Clear Cart'),
          ),
        ],
      ),
      body: productState.isLoading && productState.products.isEmpty
          ? const LoadingWidget(message: 'Loading products...')
          : productState.errorMessage != null && productState.products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load products',
                  subtitle: productState.errorMessage!,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PrimarySearchBar(
                  controller: _searchController,
                  hintText: 'Add product - search name, SKU or barcode',
                  onChanged: notifier.updateSearch,
                ),
                if (billingState.searchQuery.trim().length >= 2) ...[
                  const SizedBox(height: 8),
                  if (filteredProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No matching products found.'),
                    )
                  else
                    ...filteredProducts.map((product) {
                      final brandName = resolveMasterName(
                        brandsState.items,
                        product.brandId,
                        fallback: '',
                      );
                      final locationName = resolveMasterName(
                        locationsState.items,
                        product.locationId,
                        fallback: '',
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BillingProductTile(
                          product: product,
                          displayName: formatProductDisplayName(
                            product.name,
                            brandName,
                          ),
                          locationName: locationName,
                          onAdd: () => _addProduct(
                            product,
                            brandName: brandName,
                            locationName: locationName,
                          ),
                        ),
                      );
                    }),
                ],
                const SizedBox(height: 16),
                Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (billingState.items.isEmpty)
                  const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart is empty',
                    subtitle: 'Add products to build a bill.',
                  )
                else
                  ...billingState.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BillingCartTile(
                        item: item,
                        onIncrease: () {
                          final error = notifier.increaseQuantity(
                            item.productId,
                          );
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                        onDecrease: () =>
                            notifier.decreaseQuantity(item.productId),
                        onRemove: () => notifier.removeItem(item.productId),
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
                          'Bill Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Subtotal',
                          value: AppFormatters.currency(notifier.subtotal),
                        ),
                        const SizedBox(height: 8),
                        PrimaryTextField(
                          controller: _discountController,
                          labelText: 'Bill Discount',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: notifier.updateDiscount,
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Total',
                          value: AppFormatters.currency(notifier.total),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<BillPaymentStatus>(
                          initialValue: billingState.paymentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Payment Status',
                          ),
                          items: BillPaymentStatus.values
                              .map(
                                (status) => DropdownMenuItem<BillPaymentStatus>(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              notifier.setPaymentStatus(value);
                              if (value != BillPaymentStatus.partial) {
                                _amountPaidController.clear();
                              }
                            }
                          },
                        ),
                        if (billingState.paymentStatus ==
                            BillPaymentStatus.partial) ...[
                          const SizedBox(height: 12),
                          PrimaryTextField(
                            controller: _amountPaidController,
                            labelText: 'Amount Received',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: notifier.updateAmountPaid,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Paid',
                          value: AppFormatters.currency(notifier.amountPaid),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Due',
                          value: AppFormatters.currency(notifier.amountDue),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<BillPaymentMethod>(
                          initialValue: billingState.paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                          ),
                          items: BillPaymentMethod.values
                              .map(
                                (method) => DropdownMenuItem<BillPaymentMethod>(
                                  value: method,
                                  child: Text(method.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              notifier.setPaymentMethod(value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        PrimaryTextField(
                          controller: _customerNameController,
                          labelText: 'Customer Name (Optional)',
                          onChanged: notifier.updateCustomerName,
                        ),
                        const SizedBox(height: 12),
                        PrimaryTextField(
                          controller: _customerPhoneController,
                          labelText: 'Customer Phone (Optional)',
                          keyboardType: TextInputType.phone,
                          onChanged: notifier.updateCustomerPhone,
                        ),
                        const SizedBox(height: 12),
                        PrimaryTextField(
                          controller: _takenByController,
                          labelText: 'Taken By (Optional)',
                          onChanged: notifier.updateTakenBy,
                        ),
                        if (billingState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            billingState.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Finalize Bill',
                          onPressed: billingState.isSubmitting
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final router = GoRouter.of(context);
                                  final bill = await notifier.finalizeBill();

                                  if (!mounted) {
                                    return;
                                  }

                                  if (bill == null) {
                                    final error = ref
                                        .read(billingProvider)
                                        .errorMessage;
                                    if (error != null) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                    return;
                                  }

                                  router.pushReplacement(
                                    AppRoutes.billDetails(bill.id),
                                  );
                                },
                          isLoading: billingState.isSubmitting,
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
