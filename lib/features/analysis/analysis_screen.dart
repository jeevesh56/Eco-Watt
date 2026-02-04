import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../app/state_container.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/slab_progress_bar.dart';
import '../../data/models/bill_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/slab_model.dart';
import '../../logic/billing/billing_result.dart';
import '../appliance_detail/appliance_detail_screen.dart';
import 'analysis_controller.dart';

class _BillingViewState {
  final double units;
  final BillingResult original;
  final BillingResult current;

  const _BillingViewState({
    required this.units,
    required this.original,
    required this.current,
  });

  _BillingViewState copyWith({BillingResult? current}) {
    return _BillingViewState(
      units: units,
      original: original,
      current: current ?? this.current,
    );
  }
}

final ValueNotifier<_BillingViewState?> _billingViewStateNotifier =
    ValueNotifier<_BillingViewState?>(null);

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final latestBill = state.bills.latest;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.analysisTitle),
        actions: const [ProfileMenu()],
      ),
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

    final theme = Theme.of(context);
    final topAppliance =
        sortedBreakdown.isNotEmpty ? sortedBreakdown.first : null;
    final topAppliancePct = (topAppliance != null && totalKwh > 0)
        ? (topAppliance.normalizedKWh / totalKwh * 100)
        : 0.0;

    final energyScore = _computeEnergyScore(
      bill.unitsConsumed,
      result.billing.slabProgress,
    );
    final energyScoreLabel = _labelForScore(energyScore);
    final slab = result.billing.slabProgress;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSizes.s24),
      children: [
        // CARD 1: Month summary (always visible)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'This month',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Text(
                          '$energyScore/100 • $energyScoreLabel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatter.kwh(bill.unitsConsumed),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          'Total units',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatter.currency(
                            result.billing.totalBill.toDouble(),
                            symbol: currency,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          'Estimated bill',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Text(
                    'Current slab ${slab.currentSlabStart.toStringAsFixed(0)}–${slab.currentSlabLimit.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/month-review'),
                    child: const Text('Month in review'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s8),
              SlabProgressBar(progress: slab),
            ],
          ),
        ),

        // CARD 2: Why is my bill high? (data-driven preview)
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.s12),
            onTap: () => _showWhyHighDialog(context, result, currency),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                    child: Icon(
                      Icons.trending_up,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why is my bill high?',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          _whyHighPreview(result, currency),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),

        // CARD 3: Energy breakdown
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.s12),
            onTap: () => _showEnergyBreakdownSheet(
              context,
              chartItems,
              totalKwh,
              sectionColors,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Energy breakdown',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (topAppliance != null)
                      Text(
                        '${topAppliance.appliance.name} ${topAppliancePct.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Based on your bill: ${Formatter.kwh(bill.unitsConsumed)} total. Shares scaled from appliance usage.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.s12),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 42,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap for full breakdown',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),

        // CARD 4: Optimize & savings
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Optimize & savings',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                'You can save '
                '${Formatter.currency(result.savingsLowCost, symbol: currency)}'
                ' – '
                '${Formatter.currency(result.savingsHighCost, symbol: currency)}'
                ' / month',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.s12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _showOptimizeDialog(
                    context,
                    bill,
                    result,
                    connectionType,
                    currency,
                  ),
                  child: const Text('Optimize my bill'),
                ),
              ),
            ],
          ),
        ),

        // CARD 5: Climate & wastage (combined)
        const SizedBox(height: AppSizes.s12),
        AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.s12),
            onTap: () =>
                _showClimateAndWastageSheet(context, result, currency),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s4),
              child: Row(
                children: [
                  Icon(
                    Icons.eco_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final trees =
                                (result.co2KgCurrent / 20).round().clamp(1, 9999);
                            return Text(
                              'Your usage ≈ $trees trees 🌱',
                              style: theme.textTheme.titleMedium,
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          'Unaccounted: ${Formatter.kwh(result.wastageKWh)} (${Formatter.currency(result.wastageCost, symbol: currency)})',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Data-driven preview for "Why is my bill high?" card.
  static String _whyHighPreview(AnalysisResult result, String currency) {
    final u = result.bill.unitsConsumed;
    final total = result.billing.totalBill.toDouble();
    final parts = <String>['${Formatter.kwh(u)} (${Formatter.currency(total, symbol: currency)})'];
    if (result.topConsumers.isNotEmpty) {
      final top = result.topConsumers.first;
      final share = total > 0
          ? (top.monthlyCost / total * 100).clamp(0, 100)
          : 0.0;
      parts.add('Top: ${top.appliance.name} ~${share.toStringAsFixed(0)}%');
    }
    return parts.join(' • ') + '. Tap for details.';
  }

  void _showWhyHighDialog(
      BuildContext context, AnalysisResult result, String currency) {
    final reasons = <String>[];
    final totalBill = result.billing.totalBill.toDouble();
    final units = result.bill.unitsConsumed;

    if (result.topConsumers.isNotEmpty) {
      final top = result.topConsumers.first;
      final share =
          totalBill > 0 ? (top.monthlyCost / totalBill * 100).clamp(0, 100) : 0.0;
      reasons.add(
          '${top.appliance.name} contributes ~${share.toStringAsFixed(0)}% of your bill.');
      if (share >= 40) {
        reasons.add(
            'This appliance is a major driver of your bill this month.');
      }
    }

    final progress = result.billing.slabProgress;
    final nextUnits = progress.unitsToNextSlab;
    if (nextUnits != null && nextUnits <= 20 && nextUnits > 0) {
      reasons.add(
          'You are close to the next tariff slab (${nextUnits.toStringAsFixed(0)} units away), so additional units will be billed at a higher rate.');
    } else if (progress.nextSlabLimit == null) {
      reasons.add(
          'Your usage is already in the highest slab, so every extra unit is charged at the highest rate.');
    }

    if (reasons.isEmpty) {
      reasons.add(
          'Your bill is primarily driven by overall usage (${Formatter.kwh(units)}) across appliances and tariff slabs.');
    }

    final visibleReasons = reasons.take(3).toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why is my bill high?',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Based on your data: ${Formatter.kwh(units)} this month, bill ${Formatter.currency(totalBill, symbol: currency)}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                ...visibleReasons.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.s8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right, size: 20),
                        const SizedBox(width: AppSizes.s4),
                        Expanded(
                          child: Text(
                            r,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptimizeDialog(
    BuildContext context,
    BillModel bill,
    AnalysisResult result,
    String connectionType,
    String currency,
  ) {
    final type = connectionTypeFromString(connectionType);

    double reductionKwh = 0;
    final top = result.topConsumers;
    for (var i = 0; i < top.length; i++) {
      final t = top[i];
      final factor = i == 0 ? 0.15 : 0.1; // reduce top appliance a bit more
      reductionKwh += t.normalizedKWh * factor;
    }
    final optimizedUnits =
        (bill.unitsConsumed - reductionKwh).clamp(0.0, bill.unitsConsumed);

    final optimizedBilling = BillingEngine().calculateBill(
      connectionType: type,
      units: optimizedUnits,
    );

    final currentBillAmount = result.billing.totalBill.toDouble();
    final optimizedAmount = optimizedBilling.totalBill.toDouble();
    final savings = (currentBillAmount - optimizedAmount).clamp(0.0, double.infinity);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimize my bill',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.s12),
                Row(
                  children: [
                    Expanded(
                      child: _BillAmountTile(
                        label: 'Current bill',
                        amount: Formatter.currency(
                          currentBillAmount,
                          symbol: currency,
                        ),
                        highlight: false,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: _BillAmountTile(
                        label: 'Optimized bill',
                        amount: Formatter.currency(
                          optimizedAmount,
                          symbol: currency,
                        ),
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: savings),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) {
                    return Text(
                      'You save ${Formatter.currency(value, symbol: currency)} / month',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'This is a what-if simulation based on reducing usage of the most energy-hungry appliances. It does not change your saved data.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEnergyBreakdownSheet(
    BuildContext context,
    List<dynamic> chartItems,
    double totalKwh,
    List<Color> sectionColors,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Energy breakdown',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.s12),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: chartItems.length,
                    itemBuilder: (context, index) {
                      final item = chartItems[index];
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
                      final color = sectionColors[index % sectionColors.length];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 10,
                          backgroundColor: color,
                        ),
                        title: Text(label),
                        subtitle: Text(
                          '${Formatter.kwh(kwh)} • $pct%',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClimateAndWastageSheet(
    BuildContext context,
    AnalysisResult result,
    String currency,
  ) {
    final trees = (result.co2KgCurrent / 20).round();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Climate & wastage',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.s12),
                Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Expanded(
                      child: Text(
                        'Your usage this month is like planting $trees trees 🌱',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'Wastage = unaccounted usage: the difference between your bill units and the estimated use from your appliances. It can be standby load, meter error, or appliances not in the list.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded),
                    const SizedBox(width: AppSizes.s8),
                    Expanded(
                      child: Text(
                        'Unaccounted: ${Formatter.kwh(result.wastageKWh)} (${Formatter.currency(result.wastageCost, symbol: currency)} cost)',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'Avoidable CO₂: '
                  '${result.co2KgLow.toStringAsFixed(1)} – '
                  '${result.co2KgHigh.toStringAsFixed(1)} kg / month',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'Small changes in usage can reduce wastage and climate impact while keeping your comfort similar.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _computeEnergyScore(double units, SlabProgress progress) {
    // Base score starts high for low usage and decreases with higher units.
    double score = 100.0;
    if (units > 100) {
      score -= (units - 100) * 0.1; // every extra kWh after 100 reduces score
    }

    // Penalize being very close to the next slab.
    final remaining = progress.unitsToNextSlab;
    if (remaining != null && remaining <= 20 && remaining > 0) {
      score -= 5;
    }

    return score.clamp(0, 100).round();
  }

  String _labelForScore(int score) {
    if (score >= 80) return 'Good';
    if (score >= 60) return 'Average';
    return 'Needs Improvement';
  }
}

class _BillAmountTile extends StatelessWidget {
  final String label;
  final String amount;
  final bool highlight;

  const _BillAmountTile({
    required this.label,
    required this.amount,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlight
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.s12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

