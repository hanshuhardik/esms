import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class ExpensesDashboardScreen extends ConsumerStatefulWidget {
  const ExpensesDashboardScreen({super.key});

  @override
  ConsumerState<ExpensesDashboardScreen> createState() =>
      _ExpensesDashboardScreenState();
}

class _ExpensesDashboardScreenState
    extends ConsumerState<ExpensesDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(expenseProvider.notifier).loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final summary = ref.read(expenseProvider.notifier).summary;
    final categoryTotals = summary.categoryTotals.entries.toList()
      ..sort((left, right) => left.key.index.compareTo(right.key.index));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.expenseList),
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'View list',
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.expenseAdd),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add expense',
          ),
        ],
      ),
      body: state.isLoading && state.expenses.isEmpty
          ? const LoadingWidget(message: 'Loading expenses...')
          : state.errorMessage != null && state.expenses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load expenses',
                  subtitle: state.errorMessage!,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref
                    .read(expenseProvider.notifier)
                    .loadExpenses(forceReload: true);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth < 420
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            width: cardWidth,
                            title: 'Today',
                            value: AppFormatters.currency(summary.todayTotal),
                            icon: Icons.today_outlined,
                            color: Colors.blue,
                          ),
                          _MetricCard(
                            width: cardWidth,
                            title: 'This Week',
                            value: AppFormatters.currency(summary.weekTotal),
                            icon: Icons.date_range_outlined,
                            color: Colors.orange,
                          ),
                          _MetricCard(
                            width: cardWidth,
                            title: 'This Month',
                            value: AppFormatters.currency(summary.monthTotal),
                            icon: Icons.calendar_month_outlined,
                            color: Colors.green,
                          ),
                          _MetricCard(
                            width: cardWidth,
                            title: 'Total',
                            value: AppFormatters.currency(summary.total),
                            icon: Icons.payments_outlined,
                            color: Colors.redAccent,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.expenseList),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (categoryTotals.isEmpty)
                    const EmptyState(
                      icon: Icons.category_outlined,
                      title: 'No expense categories yet',
                      subtitle: 'Expenses will appear here after checkout.',
                    )
                  else
                    ...ExpenseCategory.values.map((category) {
                      final amount = summary.categoryTotals[category] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.redAccent.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.label,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  AppFormatters.currency(amount),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.expenseAdd),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
