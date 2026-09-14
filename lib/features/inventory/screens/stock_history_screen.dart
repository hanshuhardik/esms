import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/inventory_provider.dart';

class StockHistoryScreen extends ConsumerWidget {
  final String productId;

  const StockHistoryScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(inventoryProductProvider(productId));
    final historyAsync = ref.watch(inventoryHistoryProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Stock History')),
      body: productAsync.when(
        loading: () => const LoadingWidget(message: 'Loading stock history...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load history',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (product) {
          return historyAsync.when(
            loading: () => const LoadingWidget(message: 'Loading history...'),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load history',
                  subtitle: error.toString(),
                ),
              ),
            ),
            data: (history) {
              if (history.isEmpty) {
                return EmptyState(
                  icon: Icons.history,
                  title: 'No stock history yet',
                  subtitle:
                      'All future stock changes for ${product.name} will appear here.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = history[index];
                  final differenceColor = entry.difference >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.reason,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${entry.difference >= 0 ? '+' : ''}${entry.difference}',
                                style: TextStyle(
                                  color: differenceColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _RowValue(
                            label: 'Previous Stock',
                            value: '${entry.previousStock}',
                          ),
                          _RowValue(
                            label: 'New Stock',
                            value: '${entry.newStock}',
                          ),
                          _RowValue(
                            label: 'Date',
                            value: AppFormatters.dateTime(entry.createdAt),
                          ),
                          _RowValue(label: 'Staff', value: entry.staffName),
                          if ((entry.notes ?? '').isNotEmpty) ...[
                            _RowValue(label: 'Notes', value: entry.notes!),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RowValue extends StatelessWidget {
  final String label;
  final String value;

  const _RowValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
