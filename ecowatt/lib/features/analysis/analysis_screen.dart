import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
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

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This month', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.s8),
              Text('Units: ${Formatter.kwh(bill.unitsConsumed)}'),
              Text('Estimated cost (tariff): ${Formatter.currency(CostCalculator.costForUnits(bill.unitsConsumed, tariff), symbol: currency)}'),
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

