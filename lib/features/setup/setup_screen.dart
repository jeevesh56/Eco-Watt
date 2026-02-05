import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/slab_progress_bar.dart';
import '../../core/widgets/slab_warning_card.dart';
import '../../core/widgets/toggle_chip.dart';
import '../../core/widgets/profile_menu.dart';
import '../configuration/appliance_config_screen.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/billing_result.dart';
import '../../logic/billing/slab_model.dart';
import '../../logic/billing/reverse_slab.dart';
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
  BillingResult? _billingPreview;

  @override
  void initState() {
    super.initState();
    _valueCtrl.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _valueCtrl.removeListener(_updatePreview);
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currency = appState.settings.tariff.currency;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupTitle),
        actions: const [ProfileMenu()],
      ),
      // Keep the bottom navigation dashboard visible while in Energy Setup
      // by embedding content in a Column; BottomNavShell provides the nav bar.
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
                            onChanged: (v) {
                              _amountMode = v;
                              _updatePreview();
                            },
                          ),
                          ToggleChip<bool>(
                            value: false,
                            groupValue: _amountMode,
                            label: 'Units (kWh)',
                            onChanged: (v) {
                              _amountMode = v;
                              _updatePreview();
                            },
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
                      if (_billingPreview != null) ...[
                        const SizedBox(height: AppSizes.s16),
                        if (_isAtSlabBoundary(_billingPreview!.totalUnits.toDouble()))
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.s12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s12,
                                vertical: AppSizes.s8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSizes.s8),
                                  Expanded(
                                    child: Text(
                                      'You entered a higher tariff slab',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Text(
                          'Slab progress',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSizes.s8),
                        SlabProgressBar(progress: _billingPreview!.slabProgress),
                        SlabWarningCard(progress: _billingPreview!.slabProgress),
                        const SizedBox(height: AppSizes.s12),
                        Text(
                          'Estimated Next Bill: ${Formatter.currency(_billingPreview!.totalBill.toDouble(), symbol: currency)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                AppCard(
                  child: Row(
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

  /// Slab boundary starts that trigger "higher slab" warning: 101, 201, 401, 501, 601, 801.
  static const _slabBoundaryStarts = [101.0, 201.0, 401.0, 501.0, 601.0, 801.0];

  bool _isAtSlabBoundary(double units) {
    for (final boundary in _slabBoundaryStarts) {
      if ((units - boundary).abs() < 0.01) return true;
    }
    return false;
  }

  void _updatePreview() {
    final raw = double.tryParse(_valueCtrl.text.trim());
    if (raw == null) {
      setState(() => _billingPreview = null);
      return;
    }

    final type = connectionTypeFromString(_connectionType);
    final units = _amountMode
        ? costToUnitsForConnection(
            connectionType: type,
            totalCost: raw,
          )
        : raw;

    final billing =
        BillingEngine().calculateBill(connectionType: type, units: units);
    setState(() => _billingPreview = billing);
  }
}

