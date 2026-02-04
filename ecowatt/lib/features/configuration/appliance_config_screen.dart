import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../data/mock/appliances_catalog.dart';
import '../analysis/analysis_screen.dart';
import 'appliance_config_controller.dart';

class ApplianceConfigScreen extends StatelessWidget {
  const ApplianceConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ApplianceConfigBody();
  }
}

class _ApplianceConfigBody extends StatefulWidget {
  const _ApplianceConfigBody();

  @override
  State<_ApplianceConfigBody> createState() => _ApplianceConfigBodyState();
}

class _ApplianceConfigBodyState extends State<_ApplianceConfigBody> {
  final _controller = ApplianceConfigController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope != null) _controller.ensureCatalogSeeded(scope);
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    final appState = AppStateScope.of(context);

    // If user has not selected anything yet, show catalog as selectable cards.
    final selected = {for (final a in appState.appliances.items) a.applianceId: a};
    final catalog = AppliancesCatalog.defaults();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.configTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: ListView(
            children: [
              const ProgressBar(step: 2, totalSteps: 3),
              const SizedBox(height: AppSizes.s16),
              AppCard(
                child: Text(
                  'Select appliances and choose usage intensity (Low/Medium/High). '
                  'Daily hours are mapped automatically based on intensity.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              ...catalog.map((item) {
                final isSelected = selected.containsKey(item.applianceId);
                final current = isSelected ? selected[item.applianceId]! : item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s12),
                  child: AppCard(
                    onTap: scope == null
                        ? null
                        : () => _controller.setSelected(scope, current, !isSelected),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: scope == null
                                  ? null
                                  : (v) => _controller.setSelected(scope, current, v ?? false),
                            ),
                            Expanded(
                              child: Text(
                                '${current.name} • ${current.powerRating.toStringAsFixed(0)}W',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s8),
                        Row(
                          children: [
                            const Text('Usage:'),
                            const SizedBox(width: AppSizes.s8),
                            DropdownButton<String>(
                              value: current.usageLevel,
                              items: const [
                                DropdownMenuItem(value: 'low', child: Text('Low')),
                                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'high', child: Text('High')),
                              ],
                              onChanged: (!isSelected || scope == null)
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      _controller.updateUsageLevel(scope, current, v);
                                    },
                            ),
                            const Spacer(),
                            Text('${current.dailyHours.toStringAsFixed(0)} hrs/day'),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s8),
                        Row(
                          children: [
                            const Text('Star rating:'),
                            const SizedBox(width: AppSizes.s8),
                            DropdownButton<int>(
                              value: current.starRating,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1★')),
                                DropdownMenuItem(value: 2, child: Text('2★')),
                                DropdownMenuItem(value: 3, child: Text('3★')),
                                DropdownMenuItem(value: 4, child: Text('4★')),
                                DropdownMenuItem(value: 5, child: Text('5★')),
                              ],
                              onChanged: (!isSelected || scope == null)
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      _controller.updateStarRating(scope, current, v);
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSizes.s8),
              AppButton(
                label: 'Continue to Analysis',
                onPressed: () {
                  if (appState.appliances.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select at least one appliance to continue.')),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

