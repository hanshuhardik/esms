import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/expense_provider.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailsScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseDetailsProvider(expenseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: expenseAsync.when(
        loading: () => const LoadingWidget(message: 'Loading expense...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load expense',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (expense) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Amount',
                        value: AppFormatters.currency(expense.amount),
                      ),
                      _InfoRow(
                        label: 'Category',
                        value: expense.category.label,
                      ),
                      _InfoRow(
                        label: 'Payment Method',
                        value: expense.paymentMethod.label,
                      ),
                      _InfoRow(
                        label: 'Expense Date',
                        value: AppFormatters.dateTime(expense.expenseDate),
                      ),
                      _InfoRow(label: 'Created By', value: expense.createdBy),
                      _InfoRow(
                        label: 'Created At',
                        value: AppFormatters.dateTime(expense.createdAt),
                      ),
                      _InfoRow(
                        label: 'Updated At',
                        value: AppFormatters.dateTime(expense.updatedAt),
                      ),
                      if (expense.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(expense.description!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.expenseEdit(expense.id)),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text(
                              'Delete this expense permanently? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) {
                          return;
                        }

                        final result = await ref
                            .read(expenseProvider.notifier)
                            .deleteExpense(expense.id);
                        if (!context.mounted) {
                          return;
                        }

                        if (result.isFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.error ?? 'Unable to delete expense.',
                              ),
                            ),
                          );
                          return;
                        }

                        context.go(AppRoutes.expenseList);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
          Expanded(flex: 6, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
