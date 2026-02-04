import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/toggle_chip.dart';
import '../configuration/appliance_config_screen.dart';
import 'setup_controller.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SetupForm();
  }
}

class _SetupForm extends StatefulWidget {
  const _SetupForm();

  @override
  State<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<_SetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();

  bool _amountMode = true;
  String _connectionType = 'residential';
  int _occupants = 2;
  bool _saving = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currency = appState.settings.tariff.currency;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.setupTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Bill',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.s12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ToggleChip<bool>(
                            value: true,
                            groupValue: _amountMode,
                            label: 'Amount ($currency)',
                            onChanged: (v) => setState(() => _amountMode = v),
                          ),
                          ToggleChip<bool>(
                            value: false,
                            groupValue: _amountMode,
                            label: 'Units (kWh)',
                            onChanged: (v) => setState(() => _amountMode = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s12),
                      TextFormField(
                        controller: _valueCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.requiredNum,
                        decoration: InputDecoration(
                          labelText: _amountMode
                              ? 'Bill amount ($currency)'
                              : 'Units consumed (kWh)',
                          prefixIcon: _amountMode ? const Icon(Icons.currency_rupee) : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.s12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ToggleChip<String>(
                            value: 'residential',
                            groupValue: _connectionType,
                            label: 'Residential',
                            onChanged: (v) => setState(() => _connectionType = v),
                          ),
                          ToggleChip<String>(
                            value: 'commercial',
                            groupValue: _connectionType,
                            label: 'Commercial',
                            onChanged: (v) => setState(() => _connectionType = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s12),
                      Row(
                        children: [
                          Text(
                            'Occupants',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _occupants <= 1
                                ? null
                                : () => setState(() => _occupants--),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_occupants',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: () => setState(() => _occupants++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                AppButton(
                  label: AppStrings.calculateBreakdown,
                  isLoading: _saving,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _saving = true);
                    try {
                      if (!mounted) return;
                      final scope = context.dependOnInheritedWidgetOfExactType<
                          AppStateScope>();
                      if (scope == null) return;

                      final navigator = Navigator.of(context);
                      final controller = SetupController();
                      final value = double.parse(_valueCtrl.text.trim());
                      await controller.saveSetup(
                        scope: scope,
                        connectionType: _connectionType,
                        occupants: _occupants,
                        inputIsAmount: _amountMode,
                        inputValue: value,
                        month: now.month,
                        year: now.year,
                      );

                      if (!mounted) return;
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const ApplianceConfigScreen(),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.s16),
                AppCard(
                  child: Text(
                    'Saved locally. You can add backend later by swapping repositories in /data/repositories.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

