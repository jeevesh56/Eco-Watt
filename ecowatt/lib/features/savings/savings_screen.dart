import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/formatter.dart';
import '../../features/analysis/analysis_controller.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bill = state.bills.latest;
    if (bill == null) {
      return Scaffold(appBar: AppBar(title: const Text('Savings & Waste')), body: const Center(child: Text('No bill data')));
    }
    final analysis = AnalysisController().compute(
      bill: bill,
      appliances: state.appliances.items,
      tariff: state.settings.tariff,
      connectionType: state.settings.user?.connectionType ?? 'residential',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Savings & Waste')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: ListView(
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Potential savings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSizes.s8),
                  Text('Amount: ${Formatter.currency(analysis.savingsLowCost)} – ${Formatter.currency(analysis.savingsHighCost)} / month'),
                ]),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Top wastage', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSizes.s8),
                  ...analysis.breakdown.where((b) => b.wastageCost > 0).map((b) => ListTile(
                        title: Text(b.appliance.name),
                        subtitle: Text('Waste: ${Formatter.currency(b.wastageCost)}'),
                      )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
