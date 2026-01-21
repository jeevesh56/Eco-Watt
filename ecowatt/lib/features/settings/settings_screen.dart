import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/formatter.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
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
  bool _saving = false;

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
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    final state = AppStateScope.of(context);
    final current = state.settings.tariff;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSizes.s12),
                      TextFormField(
                        controller: _rateCtrl,
                        decoration: const InputDecoration(labelText: 'Base rate (per kWh)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.requiredNum,
                      ),
                      const SizedBox(height: AppSizes.s12),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: const [
                          DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                          DropdownMenuItem(value: r'$', child: Text(r'$ (USD)')),
                          DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? '₹'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Tiered slabs (optional)', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _tiers.add(const TariffTierModel(upToKWh: 100, rate: 8.0));
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s8),
                      if (_tiers.isEmpty)
                        Text(
                          'No slabs. Base rate will be used for all units.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ..._tiers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final tier = entry.value;
                        final upCtrl = TextEditingController(text: tier.upToKWh.toStringAsFixed(0));
                        final rateCtrl = TextEditingController(text: tier.rate.toStringAsFixed(2));
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSizes.s12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: upCtrl,
                                  decoration: const InputDecoration(labelText: 'Up to (kWh)'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: Validators.requiredNum,
                                  onChanged: (v) {
                                    final n = double.tryParse(v);
                                    if (n == null) return;
                                    _tiers[i] = TariffTierModel(upToKWh: n, rate: _tiers[i].rate);
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSizes.s12),
                              Expanded(
                                child: TextFormField(
                                  controller: rateCtrl,
                                  decoration: const InputDecoration(labelText: 'Rate'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: Validators.requiredNum,
                                  onChanged: (v) {
                                    final n = double.tryParse(v);
                                    if (n == null) return;
                                    _tiers[i] = TariffTierModel(upToKWh: _tiers[i].upToKWh, rate: n);
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _tiers.removeAt(i)),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      }),
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
                AppButton(
                  label: 'Save Settings',
                  isLoading: _saving,
                  onPressed: scope == null
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _saving = true);
                          try {
                            final tariff = TariffModel(
                              providerName: _providerCtrl.text.trim(),
                              baseRate: double.parse(_rateCtrl.text.trim()),
                              tieredPricing: _tiers.toList(),
                              currency: _currency,
                            );
                            final messenger = ScaffoldMessenger.of(context);
                            await SettingsController().saveTariff(scope, tariff);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Settings saved. Costs will recalculate automatically.')),
                            );
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

