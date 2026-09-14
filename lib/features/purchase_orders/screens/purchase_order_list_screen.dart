import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../providers/purchase_order_provider.dart';
import '../widgets/purchase_order_card.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(purchaseOrderProvider.notifier).loadPurchaseOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderProvider);
    final filteredOrders = ref
        .read(purchaseOrderProvider.notifier)
        .filteredOrders;
    final isSearchEmpty =
        state.searchQuery.isNotEmpty &&
        filteredOrders.isEmpty &&
        state.orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.purchaseOrderAdd),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrimarySearchBar(
              controller: _searchController,
              hintText: 'Search purchase orders...',
              onChanged: (value) {
                ref.read(purchaseOrderProvider.notifier).updateSearch(value);
              },
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.orders.isEmpty)
              const Expanded(
                child: LoadingWidget(message: 'Loading purchase orders...'),
              )
            else if (state.errorMessage != null && state.orders.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load purchase orders',
                  subtitle: state.errorMessage!,
                ),
              )
            else ...[
              if (state.errorMessage != null && state.orders.isNotEmpty) ...[
                _ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () {
                    ref
                        .read(purchaseOrderProvider.notifier)
                        .loadPurchaseOrders(forceReload: true);
                  },
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: filteredOrders.isEmpty
                    ? EmptyState(
                        icon: isSearchEmpty
                            ? Icons.search_off
                            : Icons.receipt_long_outlined,
                        title: isSearchEmpty
                            ? 'No matches found'
                            : 'No purchase orders yet',
                        subtitle: isSearchEmpty
                            ? 'Try a different search term.'
                            : 'Create your first purchase order to start tracking stock purchases.',
                      )
                    : ListView.separated(
                        itemCount: filteredOrders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];

                          return PurchaseOrderCard(
                            order: order,
                            onTap: () => context.push(
                              AppRoutes.purchaseOrderDetails(order.id),
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
