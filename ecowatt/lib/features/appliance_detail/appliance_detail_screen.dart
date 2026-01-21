import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../logic/calculator/cost_calculator.dart';
import '../analysis/analysis_controller.dart';
import 'appliance_detail_controller.dart';

class ApplianceDetailScreen extends StatelessWidget {
  final String applianceId;

  const ApplianceDetailScreen({super.key, required this.applianceId});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final appliance = state.appliances.byId(applianceId);
    final bill = state.bills.latest;
    if (appliance == null || bill == null) {
      return const Scaffold(
        body: Center(child: Text('Missing appliance or bill data.')),
      );
    }

    // Reuse analysis computation to keep logic centralized.
    final analysis = AnalysisController().compute(
      bill: bill,
      appliances: state.appliances.items,
      tariff: state.settings.tariff,
    );
    final row = analysis.breakdown.firstWhere((b) => b.appliance.applianceId == applianceId);

    final tariff = state.settings.tariff;
    final billCost = CostCalculator.costForUnits(bill.unitsConsumed, tariff);
    final effectiveRate = bill.unitsConsumed > 0 ? billCost / bill.unitsConsumed : tariff.baseRate;

    final detail = ApplianceDetailController().compute(
      appliance: appliance,
      effectiveRate: effectiveRate,
      normalizedMonthlyKWh: row.normalizedKWh,
      wastageCost: row.wastageCost,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Appliance Detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appliance.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSizes.s8),
                    Text('Power: ${appliance.powerRating.toStringAsFixed(0)}W • Usage: ${appliance.usageLevel} (${appliance.dailyHours.toStringAsFixed(0)} hrs/day)'),
                    Text('Star rating: ${appliance.starRating}★'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated monthly cost', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    Text('Energy: ${Formatter.kwh(detail.estimatedMonthlyKWh)}'),
                    Text('Cost: ${Formatter.currency(detail.monthlyCost, symbol: tariff.currency)}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wastage analysis', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    Text('₹ wasted: ${Formatter.currency(detail.wastageCost, symbol: tariff.currency)}'),
                    const SizedBox(height: AppSizes.s8),
                    Text('Reason: ${detail.wastageReason}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Optimization tips', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    ...detail.optimizationTips.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('- $t'),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Replacement impact', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    Text('Current: ${appliance.starRating}★  → Recommended: ${detail.recommendedStar}★'),
                    Text('Estimated savings: ${Formatter.currency(detail.replacementMonthlySavings, symbol: tariff.currency)} / month'),
                    const SizedBox(height: AppSizes.s12),
                    AppButton(
                      label: 'Shop Models (mock)',
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) {
                            final models = [
                              ('EcoCool ${detail.recommendedStar}★', detail.replacementMonthlySavings),
                              ('GreenSaver ${detail.recommendedStar}★', detail.replacementMonthlySavings * 0.9),
                              ('UltraEff ${detail.recommendedStar}★', detail.replacementMonthlySavings * 1.1),
                            ];
                            return Padding(
                              padding: const EdgeInsets.all(AppSizes.s16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recommended models', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: AppSizes.s12),
                                  ...models.map((m) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(m.$1),
                                        subtitle: Text('Estimated monthly savings: ${Formatter.currency(m.$2, symbol: tariff.currency)}'),
                                        trailing: const Icon(Icons.open_in_new),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Saved "${m.$1}" to your shortlist (local).')),
                                          );
                                        },
                                      )),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

