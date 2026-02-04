import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../app/state_container.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/slab_progress_bar.dart';
import '../../logic/calculator/cost_calculator.dart';
import '../appliance_detail/appliance_detail_screen.dart';
import 'analysis_controller.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final latestBill = state.bills.latest;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.analysisTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: latestBill == null
              ? AppCard(
                  child: Text(
                    'No bill data yet. Go to Energy Setup and add your current bill first.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : _AnalysisBody(billId: latestBill.billId),
        ),
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  final String billId;
  const _AnalysisBody({required this.billId});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bill = state.bills.bills.firstWhere((b) => b.billId == billId);
    final appliances = state.appliances.items;
    final tariff = state.settings.tariff;
    final connectionType =
        state.settings.user?.connectionType ?? 'residential';

    if (appliances.isEmpty) {
      return AppCard(
        child: Text(
          'No appliances configured yet. Go to Appliance Configuration and select appliances.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final controller = AnalysisController();
    final result = controller.compute(
      bill: bill,
      appliances: appliances,
      tariff: tariff,
      connectionType: connectionType,
    );
    final currency = tariff.currency;

    // Build pie chart sections from appliances, aggregating "Others" for clarity.
    final totalKwh =
        result.breakdown.fold<double>(0, (s, b) => s + b.normalizedKWh);
    final sortedBreakdown = [...result.breakdown]
      ..sort((a, b) => b.normalizedKWh.compareTo(a.normalizedKWh));
    final top = sortedBreakdown.take(5).toList();
    final others = sortedBreakdown.skip(5).toList();
    final chartItems = <dynamic>[...top];
    if (others.isNotEmpty) {
      final otherKwh =
          others.fold<double>(0, (s, b) => s + b.normalizedKWh);
      chartItems.add({
        'label': 'Others',
        'kwh': otherKwh,
      });
    }
    final sectionColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      AppColors.warning,
      AppColors.danger,
      Colors.tealAccent.shade200,
      Colors.grey.shade300,
    ];

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < chartItems.length; i++) {
      final item = chartItems[i];
      final double kwh;
      final String label;
      if (item is Map) {
        kwh = item['kwh'] as double;
        label = item['label'] as String;
      } else {
        kwh = item.normalizedKWh;
        label = item.appliance.name;
      }
      final value = totalKwh > 0 ? kwh / totalKwh * 100 : 0;
      sections.add(
        PieChartSectionData(
          value: kwh,
          title: '${value.toStringAsFixed(0)}%',
          color: sectionColors[i % sectionColors.length],
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This month', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Units: ${Formatter.kwh(bill.unitsConsumed)}'),
                      Text('Estimated cost (tariff): ${Formatter.currency(CostCalculator.costForUnits(bill.unitsConsumed, tariff), symbol: currency)}'),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/month-review'),
                    child: const Text('Month in Review'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              SlabProgressBar(progress: result.billing.slabProgress),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Energy breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s12),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 42,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chartItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final color = sectionColors[idx % sectionColors.length];
                  final double kwh;
                  final String label;
                  if (item is Map) {
                    kwh = item['kwh'] as double;
                    label = item['label'] as String;
                  } else {
                    kwh = item.normalizedKWh;
                    label = item.appliance.name;
                  }
                  final pct =
                      totalKwh > 0 ? (kwh / totalKwh * 100).toStringAsFixed(0) : '0';
                  return Chip(
                    backgroundColor: color.withValues(alpha: 0.14),
                    label: Text('$label • $pct%'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top consumers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              ...result.topConsumers.map((t) => Text(
                    '- ${t.appliance.name}: ${Formatter.currency(t.monthlyCost, symbol: currency)}',
                  )),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wastage estimate', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Text('Unaccounted: ${Formatter.kwh(result.wastageKWh)}'),
              Text('₹ wasted: ${Formatter.currency(result.wastageCost, symbol: currency)}'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Savings potential (10–15%)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Text('Save ${Formatter.kwh(result.savingsLowKWh)} – ${Formatter.kwh(result.savingsHighKWh)}'),
              Text('≈ ${Formatter.currency(result.savingsLowCost, symbol: currency)} – ${Formatter.currency(result.savingsHighCost, symbol: currency)} / month'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Climate impact (SDG 13)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Text('Current: ${result.co2KgCurrent.toStringAsFixed(1)} kg CO₂ / month'),
              Text('Avoidable: ${result.co2KgLow.toStringAsFixed(1)} – ${result.co2KgHigh.toStringAsFixed(1)} kg CO₂ / month'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              ...result.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('- ${r.title}: ${r.detail}'),
                  )),
              const SizedBox(height: AppSizes.s12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/savings'),
                child: const Text('Optimize Consumption'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appliance-wise breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              ...result.breakdown.map((b) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.appliance.name),
                  subtitle: Text('Energy: ${Formatter.kwh(b.normalizedKWh)} • Wastage: ${Formatter.currency(b.wastageCost, symbol: currency)}'),
                  trailing: Text(Formatter.currency(b.monthlyCost, symbol: currency)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApplianceDetailScreen(applianceId: b.appliance.applianceId),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

