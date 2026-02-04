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

  /// Residential tariff profile matching the slab structure described
  /// in the app UX (used in Energy Setup estimations).
  ///
  /// - 1–100 units: ₹0.00 / unit (subsidised)
  /// - 101–200 units: ₹2.35 / unit
  /// - 201–400 units: ₹4.70 / unit
  /// - 401–500 units: ₹6.30 / unit
  /// - 501+ units: ₹6.30 / unit (fallback at highest slab rate)
  static const TariffProfile _residentialGeneric = TariffProfile(
    connectionType: ConnectionType.residential,
    regionCode: 'IN-GEN',
    slabs: [
      Slab(
        startInclusive: 1,
        endInclusive: 100,
        ratePerUnit: 0.0,
        isSubsidised: true,
      ),
      Slab(
        startInclusive: 101,
        endInclusive: 200,
        ratePerUnit: 2.35,
      ),
      Slab(
        startInclusive: 201,
        endInclusive: 400,
        ratePerUnit: 4.70,
      ),
      Slab(
        startInclusive: 401,
        endInclusive: 500,
        ratePerUnit: 6.30,
      ),
      // Fallback for any usage above 500 units – same rate as last slab.
      Slab(
        startInclusive: 501,
        endInclusive: 9999,
        ratePerUnit: 6.30,
      ),
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

