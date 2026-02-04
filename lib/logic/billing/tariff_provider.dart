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
  /// Demo slab model aligned with ECOWATT test expectations:
  /// - 0–100 units: subsidised (treated as free)
  /// - 101–200: low rate
  /// - 201–400: higher rate
  /// - 401–∞: highest rate
  static const TariffProfile _residentialGeneric = TariffProfile(
    connectionType: ConnectionType.residential,
    regionCode: 'IN-GEN',
    slabs: [
      Slab(
        startInclusive: 0,
        endInclusive: 100,
        ratePerUnit: 0,
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

