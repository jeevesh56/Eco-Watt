import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/profile_menu.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/slab_model.dart';
import '../analysis/analysis_controller.dart';
import 'history_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bills = state.bills.bills;
    final tariff = state.settings.tariff;
    final currency = tariff.currency;
    final connectionType = state.settings.user?.connectionType ?? 'residential';
    final trends = HistoryController().buildTrends(bills);
    final lastTrends =
        trends.length > 6 ? trends.sublist(trends.length - 6) : trends;
    // Slab-calculated bill amount for each trend (single source of truth).
    final billingEngine = BillingEngine();
    final connection = connectionTypeFromString(connectionType);
    final chartAmounts = lastTrends
        .map((t) => billingEngine.calculateBill(
            connectionType: connection, units: t.bill.unitsConsumed))
        .map((r) => r.totalBill.toDouble())
        .toList();
    final maxAmount = chartAmounts.isEmpty ? 100.0 : chartAmounts.reduce((a, b) => a > b ? a : b);
    final minAmount = 0.0;
    // Round Y-axis to nice integers: maxY and interval for clean ticks
    final maxY = _niceMaxY(maxAmount);
    final yInterval = _niceInterval(maxY);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: const [ProfileMenu()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: bills.isEmpty
              ? AppCard(
                  child: Text(
                    'No saved bills yet. Add your current bill in Energy Setup.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  children: [
                    AppCard(
                      child: Text(
                        'Tap any month to view breakdown. Trends are based on month-to-month unit changes.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    // 6-month trend as line graph
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '6-month bill amount trend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSizes.s12),
                          SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (lastTrends.length - 1).toDouble(),
                                minY: minAmount,
                                maxY: maxY,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: lastTrends
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(
                                            e.key.toDouble(),
                                            chartAmounts[e.key]))
                                        .toList(),
                                    isCurved: true,
                                    color: Theme.of(context).colorScheme.primary,
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                            radius: 4,
                                            color: Theme.of(context).colorScheme.primary,
                                            strokeWidth: 2,
                                            strokeColor: Theme.of(context).colorScheme.surface,
                                          ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: yInterval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    left: BorderSide(color: Theme.of(context).dividerColor),
                                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 44,
                                      interval: yInterval,
                                      getTitlesWidget: (value, meta) {
                                        // Y-axis: integers only (no decimals)
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6.0),
                                          child: Text(
                                            '$currency${value.round()}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.round();
                                        if (index < 0 || index >= lastTrends.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            _monthName(lastTrends[index].bill.month),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    ...trends.reversed.map((t) {
                      final b = t.bill;
                      final billTotal = billingEngine.calculateBill(
                          connectionType: connection, units: b.unitsConsumed);
                      final statusText = switch (t.status) {
                        TrendStatus.increase => 'Increase',
                        TrendStatus.decrease => 'Decrease',
                        TrendStatus.stable => 'Stable',
                      };
                      final pct = t.percentChange;
                      final pctText = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.s12),
                        child: AppCard(
                          onTap: () {
                            _showBillBreakdown(context, b.billId);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_monthName(b.month)} ${b.year}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Units: ${Formatter.kwh(b.unitsConsumed)}'),
                                    Text('Amount: ${Formatter.currency(billTotal.totalBill.toDouble(), symbol: currency)}'),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(statusText),
                                  Text(pctText),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }

  void _showBillBreakdown(BuildContext context, String billId) {
    final state = AppStateScope.of(context);
    final bill = state.bills.bills.firstWhere((b) => b.billId == billId);
    final appliances = state.appliances.items;
    final tariff = state.settings.tariff;
    final connectionType =
        state.settings.user?.connectionType ?? 'residential';

    if (appliances.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Breakdown unavailable'),
          content: const Text('Configure appliances first to view breakdown.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final result = AnalysisController().compute(
      bill: bill,
      appliances: appliances,
      tariff: tariff,
      connectionType: connectionType,
    );
    final currency = tariff.currency;

    final totalBill = result.billing.totalBill.toDouble();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${_monthName(bill.month)} ${bill.year}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Units: ${Formatter.kwh(bill.unitsConsumed)}'),
              Text('Bill (slab): ${Formatter.currency(totalBill, symbol: currency)}'),
              const SizedBox(height: 8),
              Text('Unaccounted usage: ${Formatter.kwh(result.wastageKWh)} (${Formatter.currency(result.wastageCost, symbol: currency)} cost)'),
              const SizedBox(height: 12),
              const Text('Appliance-wise (cost):'),
              const SizedBox(height: 8),
              ...result.breakdown.map((a) => Text(
                    '- ${a.appliance.name}: ${Formatter.currency(a.monthlyCost, symbol: currency)}',
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const m = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  if (month < 1 || month > 12) return 'Month';
  return m[month - 1];
}

/// Rounds up to a nice Y-axis max (e.g. 847 → 900, 120 → 150).
double _niceMaxY(double maxAmount) {
  if (maxAmount <= 0) return 100;
  final padded = maxAmount * 1.15;
  if (padded <= 50) return 50;
  if (padded <= 100) return 100;
  if (padded <= 200) return 200;
  if (padded <= 500) return ((padded / 100).ceil() * 100).toDouble();
  if (padded <= 1000) return ((padded / 200).ceil() * 200).toDouble();
  return ((padded / 500).ceil() * 500).toDouble();
}

/// Returns a nice interval for Y-axis ticks (integers only).
double _niceInterval(double maxY) {
  if (maxY <= 50) return 10;
  if (maxY <= 100) return 20;
  if (maxY <= 200) return 50;
  if (maxY <= 500) return 100;
  if (maxY <= 1000) return 200;
  return 500;
}
