import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/report_models.dart';
import '../providers/reports_provider.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  ConsumerState<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState
    extends ConsumerState<ReportsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportsProvider.notifier).loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);
    final snapshot = notifier.snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => notifier.loadReports(forceReload: true),
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Expenses',
            onPressed: () => context.push(AppRoutes.expensesDashboard),
            icon: const Icon(Icons.payments_outlined),
          ),
        ],
      ),
      body: state.isLoading && state.bills.isEmpty && state.expenses.isEmpty
          ? const LoadingWidget(message: 'Loading reports...')
          : state.errorMessage != null && state.bills.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load reports',
                  subtitle: state.errorMessage!,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => notifier.loadReports(forceReload: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DateFilterBar(
                    preset: state.preset,
                    customRange: state.customRange,
                    onPresetChanged: notifier.setPreset,
                    onCustomRangePicked: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: state.customRange,
                      );
                      notifier.setCustomRange(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calendar Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Today, this week, and this month are calculated from bill and expense dates.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    metrics: [
                      _MetricSpec(
                        'Today Sales',
                        snapshot.overview.today.sales,
                        Colors.green,
                      ),
                      _MetricSpec(
                        'Today Expenses',
                        snapshot.overview.today.expenses,
                        Colors.redAccent,
                      ),
                      _MetricSpec(
                        'Today Profit',
                        snapshot.overview.today.profit,
                        Colors.blue,
                      ),
                      _MetricSpec(
                        'Week Sales',
                        snapshot.overview.week.sales,
                        Colors.green,
                      ),
                      _MetricSpec(
                        'Week Expenses',
                        snapshot.overview.week.expenses,
                        Colors.redAccent,
                      ),
                      _MetricSpec(
                        'Week Profit',
                        snapshot.overview.week.profit,
                        Colors.blue,
                      ),
                      _MetricSpec(
                        'Month Sales',
                        snapshot.overview.month.sales,
                        Colors.green,
                      ),
                      _MetricSpec(
                        'Month Expenses',
                        snapshot.overview.month.expenses,
                        Colors.redAccent,
                      ),
                      _MetricSpec(
                        'Month Profit',
                        snapshot.overview.month.profit,
                        Colors.blue,
                      ),
                      _MetricSpec(
                        'Total Bills',
                        snapshot.overview.totalBills.toDouble(),
                        Colors.orange,
                      ),
                      _MetricSpec(
                        'Total Items Sold',
                        snapshot.overview.totalItemsSold.toDouble(),
                        Colors.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Selected Range: ${_rangeLabel(snapshot.selectedRange)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    metrics: [
                      _MetricSpec(
                        'Total Sales',
                        snapshot.selectedRangeSummary.sales,
                        Colors.green,
                      ),
                      _MetricSpec(
                        'Total Expenses',
                        snapshot.selectedRangeSummary.expenses,
                        Colors.redAccent,
                      ),
                      _MetricSpec(
                        'Net Profit',
                        snapshot.selectedRangeSummary.profit,
                        Colors.blue,
                      ),
                      _MetricSpec(
                        'Bills',
                        snapshot.selectedRangeSummary.billCount.toDouble(),
                        Colors.orange,
                      ),
                      _MetricSpec(
                        'Items Sold',
                        snapshot.selectedRangeSummary.itemsSold.toDouble(),
                        Colors.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Sales vs Expenses',
                    child: _SalesExpenseChart(points: snapshot.salesVsExpenses),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: 'Expenses by Category',
                          child: _BarValueChart(
                            values: snapshot.expenseReport.expensesByCategory,
                            valueColor: Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SectionCard(
                          title: 'Payment Methods',
                          child: _PaymentPieChart(
                            values: snapshot.salesReport.salesByPaymentMethod,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Top Selling Products',
                    child: _TopProductsChart(
                      items: snapshot.salesReport.topProducts,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Sales Report',
                    child: _SummaryList(
                      rows: [
                        _SummaryRowData(
                          'Total sales',
                          AppFormatters.currency(
                            snapshot.salesReport.totalSales,
                          ),
                        ),
                        _SummaryRowData(
                          'Bills',
                          '${snapshot.salesReport.billCount}',
                        ),
                        _SummaryRowData(
                          'Average bill value',
                          AppFormatters.currency(
                            snapshot.salesReport.averageBillValue,
                          ),
                        ),
                        _SummaryRowData(
                          'Items sold',
                          '${snapshot.salesReport.itemsSold}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Expense Report',
                    child: _SummaryList(
                      rows: [
                        _SummaryRowData(
                          'Total expenses',
                          AppFormatters.currency(
                            snapshot.expenseReport.totalExpenses,
                          ),
                        ),
                        _SummaryRowData(
                          'Expense count',
                          '${snapshot.expenseReport.expenseCount}',
                        ),
                        _SummaryRowData(
                          'Highest categories',
                          snapshot.expenseReport.highestExpenseCategories
                              .map(
                                (value) =>
                                    '${value.label}: ${AppFormatters.currency(value.value)}',
                              )
                              .join(' • '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Profit Report',
                    child: _SummaryList(
                      rows: [
                        _SummaryRowData(
                          'Revenue',
                          AppFormatters.currency(snapshot.profitReport.revenue),
                        ),
                        _SummaryRowData(
                          'Cost of goods sold',
                          AppFormatters.currency(
                            snapshot.profitReport.costOfGoodsSold,
                          ),
                        ),
                        _SummaryRowData(
                          'Expenses',
                          AppFormatters.currency(
                            snapshot.profitReport.expenses,
                          ),
                        ),
                        _SummaryRowData(
                          'Net profit',
                          AppFormatters.currency(
                            snapshot.profitReport.netProfit,
                          ),
                        ),
                        _SummaryRowData(
                          'Cost limitation',
                          snapshot.profitReport.limitationNote,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Inventory Report',
                    child: _SummaryList(
                      rows: [
                        _SummaryRowData(
                          'Total products',
                          '${snapshot.inventoryReport.totalProducts}',
                        ),
                        _SummaryRowData(
                          'Total stock quantity',
                          '${snapshot.inventoryReport.totalStockQuantity}',
                        ),
                        _SummaryRowData(
                          'Low-stock products',
                          '${snapshot.inventoryReport.lowStockProducts}',
                        ),
                        _SummaryRowData(
                          'Out-of-stock products',
                          '${snapshot.inventoryReport.outOfStockProducts}',
                        ),
                        _SummaryRowData(
                          'Inventory value',
                          AppFormatters.currency(
                            snapshot.inventoryReport.inventoryValue,
                          ),
                        ),
                        _SummaryRowData(
                          'Potential sales value',
                          AppFormatters.currency(
                            snapshot.inventoryReport.potentialSalesValue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Purchase Report',
                    child: _SummaryList(
                      rows: [
                        _SummaryRowData(
                          'Total purchase orders',
                          '${snapshot.purchaseReport.totalPurchaseOrders}',
                        ),
                        _SummaryRowData(
                          'Total purchase value',
                          AppFormatters.currency(
                            snapshot.purchaseReport.totalPurchaseValue,
                          ),
                        ),
                        _SummaryRowData(
                          'Pending purchase orders',
                          '${snapshot.purchaseReport.pendingPurchaseOrders}',
                        ),
                        _SummaryRowData(
                          'Received purchase orders',
                          '${snapshot.purchaseReport.receivedPurchaseOrders}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _rangeLabel(DateTimeRange range) {
    return '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}';
  }
}

class _DateFilterBar extends StatelessWidget {
  final ReportsDatePreset preset;
  final DateTimeRange? customRange;
  final ValueChanged<ReportsDatePreset> onPresetChanged;
  final VoidCallback onCustomRangePicked;

  const _DateFilterBar({
    required this.preset,
    required this.customRange,
    required this.onPresetChanged,
    required this.onCustomRangePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...ReportsDatePreset.values.map(
          (value) => ChoiceChip(
            label: Text(value.label),
            selected: preset == value,
            onSelected: (_) {
              onPresetChanged(value);
              if (value == ReportsDatePreset.custom) {
                onCustomRangePicked();
              }
            },
          ),
        ),
        if (preset == ReportsDatePreset.custom && customRange != null)
          TextButton.icon(
            onPressed: onCustomRangePicked,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              '${AppFormatters.date(customRange!.start)} - ${AppFormatters.date(customRange!.end)}',
            ),
          ),
      ],
    );
  }
}

class _MetricSpec {
  final String label;
  final double value;
  final Color color;

  const _MetricSpec(this.label, this.value, this.color);
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricSpec> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: metric.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              Icons.show_chart_outlined,
                              color: metric.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.label,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  metric.value == metric.value.roundToDouble()
                                      ? metric.value.toInt().toString()
                                      : AppFormatters.currency(metric.value),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRowData {
  final String label;
  final String value;

  const _SummaryRowData(this.label, this.value);
}

class _SummaryList extends StatelessWidget {
  final List<_SummaryRowData> rows;

  const _SummaryList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Text(row.value, textAlign: TextAlign.right)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SalesExpenseChart extends StatelessWidget {
  final List<ReportsDailyValue> points;

  const _SalesExpenseChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'No chart data',
        subtitle: 'Select a different date range.',
      );
    }

    final salesSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var index = 0; index < points.length; index++) {
      salesSpots.add(FlSpot(index.toDouble(), points[index].sales));
      expenseSpots.add(FlSpot(index.toDouble(), points[index].expenses));
    }

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: salesSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.08),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withValues(alpha: 0.08),
              ),
            ),
          ],
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(AppFormatters.date(points[index].date)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _BarValueChart extends StatelessWidget {
  final List<ReportsNamedValue> values;
  final Color valueColor;

  const _BarValueChart({required this.values, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No chart data',
        subtitle: 'Nothing to display for this range.',
      );
    }

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              values
                  .map((value) => value.value)
                  .fold<double>(0, (a, b) => a > b ? a : b) *
              1.2,
          barGroups: [
            for (var index = 0; index < values.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index].value,
                    width: 18,
                    color: valueColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= values.length) {
                    return const SizedBox.shrink();
                  }
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(values[index].label),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _PaymentPieChart extends StatelessWidget {
  final List<ReportsNamedValue> values;

  const _PaymentPieChart({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'No chart data',
        subtitle: 'No payment method distribution yet.',
      );
    }

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.redAccent,
    ];

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 34,
          sections: [
            for (var index = 0; index < values.length; index++)
              PieChartSectionData(
                value: values[index].value <= 0 ? 1 : values[index].value,
                title: values[index].label,
                radius: 78,
                color: colors[index % colors.length],
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsChart extends StatelessWidget {
  final List<ReportsTopProduct> items;

  const _TopProductsChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.local_fire_department_outlined,
        title: 'No top products yet',
        subtitle: 'Sales data will populate this chart.',
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.quantitySold}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      AppFormatters.currency(item.revenue),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
