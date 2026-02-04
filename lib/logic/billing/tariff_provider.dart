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

  /// Simple approximation of many DISCOM slabs in India for residential use.
  ///
  /// - 0–50 units: subsidised (treated as free here for awareness)
  /// - 51–150: low rate
  /// - 151–300: higher rate
  /// - 301–∞: highest rate
  static const TariffProfile _residentialGeneric = TariffProfile(
    connectionType: ConnectionType.residential,
    regionCode: 'IN-GEN',
    slabs: [
      Slab(startInclusive: 0, endInclusive: 50, ratePerUnit: 0, isSubsidised: true),
      Slab(startInclusive: 51, endInclusive: 150, ratePerUnit: 3.25),
      Slab(startInclusive: 151, endInclusive: 300, ratePerUnit: 5.75),
      Slab(startInclusive: 301, endInclusive: 9999, ratePerUnit: 7.0),
    ],
    fixedCharge: 50,
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

