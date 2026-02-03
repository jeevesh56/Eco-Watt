import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/formatter.dart';
import '../../logic/calculator/carbon_calculator.dart';

class MonthReviewScreen extends StatelessWidget {
  const MonthReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bill = state.bills.latest;
    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Month in Review')),
        body: const Center(child: Text('No bill available.')),
      );
    }

    final co2 = CarbonCalculator.kgCO2(bill.unitsConsumed);

    return Scaffold(
      appBar: AppBar(title: const Text('Month in Review')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Savings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    Text('Estimated saved this month: ${Formatter.currency(0.0)}'),
                    const SizedBox(height: AppSizes.s8),
                    Text('Improvement: 0%'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appliance breakdown', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    const Text('See analysis for appliance-level detail.'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco impact', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.s8),
                    Text('CO₂ emitted: ${co2.toStringAsFixed(1)} kg'),
                    Text('Trees saved: ${(co2 / 21).toStringAsFixed(1)} (est.)'),
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
