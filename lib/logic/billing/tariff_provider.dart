import 'slab_model.dart';

/// Central tariff configuration for ECOWATT.
///
/// In a real deployment, this layer would be backed by a remote config or
/// electricity board data. For now, values are defined here, not in UI.
class TariffProvider {
  static TariffProfile profileFor(ConnectionType type) {
    switch (type) {
      case ConnectionType.commercial:
        return _commercialGeneric;
      case ConnectionType.residential:
        return _residentialGeneric;
    }
  }

  /// Residential tariff profile — MANDATORY slab table:
  /// 1–100   → ₹0.00 | 101–200 → ₹2.35 | 201–400 → ₹4.70 | 401–500 → ₹6.30
  /// 501–600 → ₹8.40 | 601–800 → ₹9.45 | 801+    → ₹10.50
  static const TariffProfile _residentialGeneric = TariffProfile(
    connectionType: ConnectionType.residential,
    regionCode: 'IN-GEN',
    slabs: [
      Slab(startInclusive: 1, endInclusive: 100, ratePerUnit: 0.00, isSubsidised: true),
      Slab(startInclusive: 101, endInclusive: 200, ratePerUnit: 2.35),
      Slab(startInclusive: 201, endInclusive: 400, ratePerUnit: 4.70),
      Slab(startInclusive: 401, endInclusive: 500, ratePerUnit: 6.30),
      Slab(startInclusive: 501, endInclusive: 600, ratePerUnit: 8.40),
      Slab(startInclusive: 601, endInclusive: 800, ratePerUnit: 9.45),
      Slab(startInclusive: 801, endInclusive: 9999, ratePerUnit: 10.50),
    ],
    fixedCharge: 0,
  );

  /// Commercial connections usually have no subsidy and higher effective rates.
  ///
  /// Here we model:
  /// - 0–100 units: single rate
  /// - 101–∞: slightly higher rate
  static const TariffProfile _commercialGeneric = TariffProfile(
    connectionType: ConnectionType.commercial,
    regionCode: 'IN-GEN',
    slabs: [
      Slab(startInclusive: 0, endInclusive: 100, ratePerUnit: 7.0),
      Slab(startInclusive: 101, endInclusive: 9999, ratePerUnit: 8.5),
    ],
    fixedCharge: 150,
  );
}

