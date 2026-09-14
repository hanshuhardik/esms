import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(expenseProvider.notifier).loadExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final filteredExpenses = notifier.filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense List'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.expenseAdd),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add expense',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.expenseAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PrimarySearchBar(
                    controller: _searchController,
                    hintText:
                        'Search title, description, category, or payment method...',
                    onChanged: notifier.updateSearch,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory?>(
                    initialValue: state.categoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Category Filter',
                    ),
                    items: [
                      const DropdownMenuItem<ExpenseCategory?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...ExpenseCategory.values.map(
                        (category) => DropdownMenuItem<ExpenseCategory?>(
                          value: category,
                          child: Text(category.label),
                        ),
                      ),
                    ],
                    onChanged: notifier.setCategoryFilter,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDateRange: state.dateRange,
                            );
                            notifier.setDateRange(picked);
                          },
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            state.dateRange == null
                                ? 'Date Range'
                                : '${AppFormatters.date(state.dateRange!.start)} - ${AppFormatters.date(state.dateRange!.end)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed:
                            state.searchQuery.isEmpty &&
                                state.categoryFilter == null &&
                                state.dateRange == null
                            ? null
                            : notifier.clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredExpenses.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title:
                                state.searchQuery.isNotEmpty ||
                                    state.categoryFilter != null ||
                                    state.dateRange != null
                                ? 'No expenses match your filters'
                                : 'No expenses yet',
                            subtitle:
                                state.searchQuery.isNotEmpty ||
                                    state.categoryFilter != null ||
                                    state.dateRange != null
                                ? 'Try changing the search or filters.'
                                : 'Add your first expense to begin tracking shop costs.',
                          )
                        : ListView.separated(
                            itemCount: filteredExpenses.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final expense = filteredExpenses[index];
                              return _ExpenseCard(
                                expense: expense,
                                onTap: () => context.push(
                                  AppRoutes.expenseDetails(expense.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;

  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    AppFormatters.currency(expense.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(expense.category.label)),
                  Chip(label: Text(expense.paymentMethod.label)),
                ],
              ),
              if (expense.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(expense.description!),
              ],
              const SizedBox(height: 8),
              Text(AppFormatters.dateTime(expense.expenseDate)),
            ],
          ),
        ),
      ),
    );
  }
}
