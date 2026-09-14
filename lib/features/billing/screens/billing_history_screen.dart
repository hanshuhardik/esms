import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../models/bill_model.dart';
import '../providers/billing_provider.dart';

class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() =>
      _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(billingHistoryProvider.notifier).loadBills();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingHistoryProvider);
    final filteredBills = ref
        .read(billingHistoryProvider.notifier)
        .filteredBills;
    final notifier = ref.read(billingHistoryProvider.notifier);
    final isSearchEmpty =
        state.searchQuery.isNotEmpty &&
        filteredBills.isEmpty &&
        state.bills.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrimarySearchBar(
              controller: _searchController,
              hintText: 'Search by bill number, customer, or phone...',
              onChanged: notifier.updateSearch,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: BillListFilter.values.map((filter) {
                final selected = state.filter == filter;
                return FilterChip(
                  label: Text(filter.label),
                  selected: selected,
                  onSelected: (_) => notifier.updateFilter(filter),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.bills.isEmpty)
              const Expanded(child: LoadingWidget(message: 'Loading bills...'))
            else if (state.errorMessage != null && state.bills.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load bills',
                  subtitle: state.errorMessage!,
                ),
              )
            else ...[
              if (state.errorMessage != null && state.bills.isNotEmpty) ...[
                _ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () {
                    notifier.loadBills(forceReload: true);
                  },
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: filteredBills.isEmpty
                    ? EmptyState(
                        icon: isSearchEmpty
                            ? Icons.search_off
                            : Icons.receipt_long_outlined,
                        title: isSearchEmpty
                            ? 'No matches found'
                            : 'No bills yet',
                        subtitle: isSearchEmpty
                            ? 'Try a different search term.'
                            : 'Completed bills will appear here after checkout.',
                      )
                    : ListView.separated(
                        itemCount: filteredBills.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bill = filteredBills[index];
                          return _BillCard(
                            bill: bill,
                            onTap: () =>
                                context.push(AppRoutes.billDetails(bill.id)),
                            onEdit: bill.status == BillStatus.completed
                                ? () => context.push(
                                    AppRoutes.billEdit(bill.id),
                                    extra: bill,
                                  )
                                : null,
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

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _BillCard({required this.bill, required this.onTap, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bill.status) {
      BillStatus.draft => Colors.grey,
      BillStatus.completed => Colors.green,
      BillStatus.cancelled => Theme.of(context).colorScheme.error,
    };

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
                      bill.billNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(bill.status.label),
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Created by: ${bill.createdBy}'),
              if (bill.customerName?.isNotEmpty == true)
                Text('Customer: ${bill.customerName}'),
              if (bill.customerPhone?.isNotEmpty == true)
                Text('Phone: ${bill.customerPhone}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormatters.currency(bill.total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit Bill',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              Text('Total: ${AppFormatters.currency(bill.total)}'),
              Text(
                'Paid: ${AppFormatters.currency(bill.amountPaid)}  '
                'Due: ${AppFormatters.currency(bill.amountDue)}',
              ),
              Text('Status: ${bill.paymentStatus.label}'),
              const SizedBox(height: 4),
              Text(AppFormatters.dateTime(bill.createdAt)),
            ],
          ),
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
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
