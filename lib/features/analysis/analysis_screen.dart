import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/slab_progress_bar.dart';
import '../../data/models/bill_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/slab_model.dart';
import '../../logic/billing/billing_result.dart';
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

    // Calculate billing using single source of truth
    final billing = BillingEngine().calculateBill(
      connectionType: connectionTypeFromString(connectionType),
      units: bill.unitsConsumed,
    );

    final energyScore = _computeEnergyScore(
      bill.unitsConsumed,
      billing.slabProgress,
    );
    final energyScoreLabel = _labelForScore(energyScore);
    final slab = billing.slabProgress;

    // Build breakdown for energy modal
    final totalKwh =
        result.breakdown.fold<double>(0, (s, b) => s + b.normalizedKWh);
    final sortedBreakdown = [...result.breakdown]
      ..sort((a, b) => b.normalizedKWh.compareTo(a.normalizedKWh));

    final theme = Theme.of(context);

    // Fit in ONE screen - no scroll, use Column with Expanded
    return Column(
      children: [
        // CARD 1: Summary (non-clickable)
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
                            billing.totalBill.toDouble(),
                            symbol: currency,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s4),
                        Text(
                          'Total bill',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Text(
                'Current slab ${slab.currentSlabStart.toStringAsFixed(0)}–${slab.currentSlabLimit.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.s8),
              SlabProgressBar(progress: slab),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.s12),

        // CARD 2: Why is my bill high? (clickable)
        Expanded(
          child: AppCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.s12),
              onTap: () => _showWhyHighModal(context, result),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                      child: Icon(
                        Icons.trending_up,
                        color: theme.colorScheme.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Why is my bill high?',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSizes.s4),
                          Text(
                            'Tap to see key reasons',
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
        ),

        const SizedBox(height: AppSizes.s12),

        // CARD 3: Energy breakdown (clickable)
        Expanded(
          child: AppCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.s12),
              onTap: () => _showEnergyBreakdownModal(
                context,
                sortedBreakdown,
                totalKwh,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.s8),
                        Expanded(
                          child: Text(
                            'Energy breakdown',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s8),
                    if (sortedBreakdown.isNotEmpty)
                      Text(
                        'Top: ${sortedBreakdown.first.appliance.name}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.s12),

        // CARD 4: Optimization & wastage (clickable)
        Expanded(
          child: AppCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.s12),
              onTap: () => _showOptimizationModal(
                context,
                bill,
                result,
                connectionType,
                currency,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.s8),
                        Expanded(
                          child: Text(
                            'Optimization & wastage',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      'Save ${Formatter.currency(result.savingsLowCost, symbol: currency)}–${Formatter.currency(result.savingsHighCost, symbol: currency)} / month',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showWhyHighModal(BuildContext context, AnalysisResult result) {
    final reasons = <String>[];
    if (result.topConsumers.isNotEmpty) {
      final top = result.topConsumers.first;
      final totalBill = result.billing.totalBill.toDouble();
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
          'You are close to the next tariff slab, so additional units will be billed at a higher rate.');
    } else if (progress.nextSlabLimit == null) {
      reasons.add(
          'Your usage is already in the highest slab, so every extra unit is charged at the highest rate.');
    }

    if (reasons.isEmpty) {
      reasons.add(
          'Your bill is primarily driven by overall usage across appliances and fixed charges.');
    }

    final visibleReasons = reasons.take(3).toList();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.s16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 400,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(AppSizes.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Why is my bill high?',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: visibleReasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.s12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 20),
                              const SizedBox(width: AppSizes.s8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
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

  void _showEnergyBreakdownModal(
    BuildContext context,
    List<ApplianceBreakdown> breakdown,
    double totalKwh,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.s16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 500,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(AppSizes.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Energy breakdown',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: breakdown.length,
                    itemBuilder: (context, index) {
                      final item = breakdown[index];
                      final pct = totalKwh > 0
                          ? (item.normalizedKWh / totalKwh * 100)
                          : 0.0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(item.appliance.name),
                        subtitle: Text(Formatter.kwh(item.normalizedKWh)),
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

  void _showOptimizationModal(
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
      final factor = i == 0 ? 0.15 : 0.1;
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

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.s16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 500,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(AppSizes.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Optimization & wastage',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          'You save ${Formatter.currency(savings, symbol: currency)} / month',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s16),
                        Text(
                          'Wastage: ${Formatter.currency(result.wastageCost, symbol: currency)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s8),
                        Text(
                          'Small changes in usage can reduce wastage and climate impact.',
                          style: theme.textTheme.bodySmall,
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

  int _computeEnergyScore(double units, SlabProgress progress) {
    double score = 100.0;
    if (units > 100) {
      score -= (units - 100) * 0.1;
    }
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
