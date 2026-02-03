import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/sizes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
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
    final trends = HistoryController().buildTrends(bills);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle)),
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
                    // 6-month bar trend chart
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('6-month trend', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSizes.s12),
                          SizedBox(
                            height: 160,
                            child: BarChart(
                              BarChartData(
                                barGroups: trends.reversed.take(6).toList().asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final trend = entry.value as dynamic; // BillTrend
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: trend.bill.unitsConsumed,
                                        color: index == 0 ? Theme.of(context).colorScheme.primary : AppColors.greenAccent,
                                      ),
                                    ],
                                  );
                                }).toList(),
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                    Text('Amount: ${Formatter.currency(b.billAmount, symbol: currency)}'),
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
              const SizedBox(height: 8),
              Text('Estimated wastage: ${Formatter.currency(result.wastageCost, symbol: currency)}'),
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

