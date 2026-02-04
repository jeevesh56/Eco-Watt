import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../app/routes.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/tariff_model.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsBody();
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  final _formKey = GlobalKey<FormState>();
  final _rateCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  String _currency = '₹';
  final List<TariffTierModel> _tiers = [];

  @override
  void dispose() {
    _rateCtrl.dispose();
    _providerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tariff = AppStateScope.of(context).settings.tariff;
    _providerCtrl.text = tariff.providerName;
    _rateCtrl.text = tariff.baseRate.toStringAsFixed(2);
    _currency = tariff.currency;
    _tiers
      ..clear()
      ..addAll(tariff.tieredPricing);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final current = state.settings.tariff;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Sign in / Register',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          ),
        ],
      ),
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
                      Text('Tariff settings', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSizes.s12),
                      TextFormField(
                        controller: _providerCtrl,
                        decoration: const InputDecoration(labelText: 'Provider name'),
                        enabled: true,
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: AppSizes.s12),
                      TextFormField(
                        controller: _rateCtrl,
                        decoration: const InputDecoration(labelText: 'Base rate (per kWh)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: true,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSizes.s12),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: const [
                          DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? '₹'),
                      ),
                      const SizedBox(height: AppSizes.s12),
                      AppButton(
                        label: 'Save',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final tariff = TariffModel(
                            providerName: _providerCtrl.text.trim(),
                            baseRate: double.tryParse(_rateCtrl.text.trim()) ?? 0.0,
                            currency: _currency,
                            tieredPricing: _tiers,
                          );
                          final scope = AppStateScope.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          await SettingsController().saveTariff(scope, tariff);
                          if (!mounted) return;
                          messenger.showSnackBar(const SnackBar(content: Text('Tariff saved')));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                AppCard(
                  child: Text(
                    'Current base rate: ${Formatter.currency(current.baseRate, symbol: _currency)} per kWh',
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


