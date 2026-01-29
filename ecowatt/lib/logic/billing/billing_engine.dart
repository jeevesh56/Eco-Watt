import 'billing_result.dart';
import 'commercial_billing.dart';
import 'residential_billing.dart';
import 'slab_model.dart';
import 'tariff_provider.dart';

/// Single entry point for all billing calculations.
///
/// UI and controllers should only call this engine; they must not know about
/// slabs, subsidies or tariff internals.
class BillingEngine {
  BillingResult calculateBill({
    required ConnectionType connectionType,
    required double units,
  }) {
    final profile = TariffProvider.profileFor(connectionType);

    switch (connectionType) {
      case ConnectionType.residential:
        return calculateResidentialBill(profile: profile, units: units);
      case ConnectionType.commercial:
        return calculateCommercialBill(profile: profile, units: units);
    }
  }
}

