import '../../data/models/tariff_model.dart';

/// Cost rules using base rate + optional tiered slabs.
/// Keep all tariff math here (UI should never compute costs).
class CostCalculator {
  /// Calculates bill cost from kWh using tariff tiers.
  /// If no tiers exist, uses baseRate for all units.
  static double costForUnits(double unitsKWh, TariffModel tariff) {
    if (unitsKWh <= 0) return 0;
    if (tariff.tieredPricing.isEmpty) {
      return unitsKWh * tariff.baseRate;
    }

    final tiers = tariff.tieredPricing.toList()
      ..sort((a, b) => a.upToKWh.compareTo(b.upToKWh));

    double remaining = unitsKWh;
    double lowerBound = 0;
    double total = 0;

    for (final tier in tiers) {
      final cap = tier.upToKWh;
      if (cap <= lowerBound) continue;

      final tierUnits = (cap - lowerBound).clamp(0, remaining);
      total += tierUnits * tier.rate;
      remaining -= tierUnits;
      lowerBound = cap;

      if (remaining <= 0) break;
    }

    // Units above last slab use baseRate as fallback.
    if (remaining > 0) {
      total += remaining * tariff.baseRate;
    }

    return total;
  }
}

