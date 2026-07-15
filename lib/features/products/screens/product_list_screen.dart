import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../../master/providers/master_provider.dart';
import '../providers/product_provider.dart';
import '../utils/product_master_lookup.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(productProvider.notifier).loadProducts();
      ref
          .read(masterProvider(FirestoreCollections.brands).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.categories).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.locations).notifier)
          .loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final brandsState = ref.watch(masterProvider(FirestoreCollections.brands));
    final categoriesState = ref.watch(
      masterProvider(FirestoreCollections.categories),
    );
    final locationsState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );
    final filteredProducts = ref
        .read(productProvider.notifier)
        .filteredProducts;

    final isLoadingMasters =
        brandsState.isLoading ||
        categoriesState.isLoading ||
        locationsState.isLoading;
    final isSearchEmpty =
        state.searchQuery.isNotEmpty &&
        filteredProducts.isEmpty &&
        state.products.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.productAdd),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrimarySearchBar(
              controller: _searchController,
              hintText: 'Search products...',
              onChanged: (value) {
                ref.read(productProvider.notifier).updateSearch(value);
              },
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.products.isEmpty)
              const Expanded(
                child: LoadingWidget(message: 'Loading products...'),
              )
            else if (isLoadingMasters)
              const Expanded(
                child: LoadingWidget(message: 'Loading master data...'),
              )
            else if (state.errorMessage != null && state.products.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load products',
                  subtitle: state.errorMessage!,
                ),
              )
            else ...[
              if (state.errorMessage != null && state.products.isNotEmpty) ...[
                _ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () {
                    ref
                        .read(productProvider.notifier)
                        .loadProducts(forceReload: true);
                  },
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: filteredProducts.isEmpty
                    ? EmptyState(
                        icon: isSearchEmpty
                            ? Icons.search_off
                            : Icons.inventory_2_outlined,
                        title: isSearchEmpty
                            ? 'No matches found'
                            : 'No Products Yet',
                        subtitle: isSearchEmpty
                            ? 'Try a different search term.'
                            : 'Tap + to add your first product.',
                      )
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          return ProductCard(
                            product: product,
                            brandName: resolveMasterName(
                              brandsState.items,
                              product.brandId,
                            ),
                            categoryName: resolveMasterName(
                              categoriesState.items,
                              product.categoryId,
                            ),
                            locationName: resolveMasterName(
                              locationsState.items,
                              product.locationId,
                            ),
                            onTap: () => context.push(
                              AppRoutes.productDetails(product.id),
                            ),
                            onEdit: () =>
                                context.push(AppRoutes.productEdit(product.id)),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: Text('Delete "${product.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) {
                                return;
                              }

                              final errorMessage = await ref
                                  .read(productProvider.notifier)
                                  .deleteProduct(product.id);

                              if (!context.mounted) {
                                return;
                              }

                              if (errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
