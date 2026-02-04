// Core billing domain models for slab-based tariffs.
//
// This layer represents how electricity boards model tariffs – completely
// independent from any UI widgets.

/// Connection type for the ECOWATT app.
/// Values intentionally match persisted strings.
enum ConnectionType {
  residential,
  commercial,
}

ConnectionType connectionTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'commercial':
      return ConnectionType.commercial;
    case 'residential':
    default:
      return ConnectionType.residential;
  }
}

String connectionTypeToString(ConnectionType type) {
  switch (type) {
    case ConnectionType.commercial:
      return 'commercial';
    case ConnectionType.residential:
      return 'residential';
  }
}

/// A single slab in a tiered tariff.
///
/// Example: 0–100 units @ ₹0 (subsidised), 101–200 units @ ₹3.50 etc.
class Slab {
  final double startInclusive;
  final double endInclusive;
  final double ratePerUnit;
  final bool isSubsidised; // true when unit charge is waived or discounted

  const Slab({
    required this.startInclusive,
    required this.endInclusive,
    required this.ratePerUnit,
    this.isSubsidised = false,
  });

  bool contains(double unit) =>
      unit >= startInclusive && unit <= endInclusive;
}

/// Tariff profile for a given connection type + region.
class TariffProfile {
  final ConnectionType connectionType;
  final String regionCode; // allows future state-wise logic
  final List<Slab> slabs;
  final num fixedCharge; // per-bill fixed cost (often integer rupees)

  const TariffProfile({
    required this.connectionType,
    required this.regionCode,
    required this.slabs,
    this.fixedCharge = 0,
  });
}

