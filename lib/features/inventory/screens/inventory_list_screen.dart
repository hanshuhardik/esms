import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../../master/providers/master_provider.dart';
import '../models/inventory_enums.dart';
import '../providers/inventory_provider.dart';
import '../utils/product_master_lookup.dart';
import '../widgets/inventory_product_card.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  final String title;
  final InventoryListFilter filter;

  const InventoryListScreen({
    super.key,
    required this.title,
    required this.filter,
  });

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(inventoryProvider.notifier).loadInventory();
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
    final state = ref.watch(inventoryProvider);
    final brandsState = ref.watch(masterProvider(FirestoreCollections.brands));
    final categoriesState = ref.watch(
      masterProvider(FirestoreCollections.categories),
    );
    final locationsState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );
    final filteredItems = ref
        .read(inventoryProvider.notifier)
        .filteredItems(widget.filter);

    final loadingMasters =
        brandsState.isLoading ||
        categoriesState.isLoading ||
        locationsState.isLoading;
    final isSearchEmpty =
        state.searchQuery.isNotEmpty &&
        filteredItems.isEmpty &&
        state.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrimarySearchBar(
              controller: _searchController,
              hintText: 'Search inventory...',
              onChanged: (value) {
                ref.read(inventoryProvider.notifier).updateSearch(value);
              },
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.items.isEmpty)
              const Expanded(
                child: LoadingWidget(message: 'Loading inventory...'),
              )
            else if (loadingMasters)
              const Expanded(
                child: LoadingWidget(message: 'Loading master data...'),
              )
            else if (state.errorMessage != null && state.items.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load inventory',
                  subtitle: state.errorMessage!,
                ),
              )
            else ...[
              if (state.errorMessage != null && state.items.isNotEmpty) ...[
                _ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () {
                    ref
                        .read(inventoryProvider.notifier)
                        .loadInventory(forceReload: true);
                  },
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: filteredItems.isEmpty
                    ? EmptyState(
                        icon: isSearchEmpty
                            ? Icons.search_off
                            : Icons.inventory_2_outlined,
                        title: isSearchEmpty
                            ? 'No matches found'
                            : widget.filter.label,
                        subtitle: isSearchEmpty
                            ? 'Try a different search term.'
                            : 'No inventory items match this view.',
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final product = filteredItems[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InventoryProductCard(
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
                                AppRoutes.inventoryProductDetails(product.id),
                              ),
                            ),
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
