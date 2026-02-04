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

    // Sort tiers by upper bound and apply slab formula:
    // Units_i = max(0, min(U, End_i) − Start_i)
    // Cost_i  = Units_i × Rate_i
    // Total   = Σ Cost_i, with an extra slab above the last tier at baseRate.
    final tiers = tariff.tieredPricing.toList()
      ..sort((a, b) => a.upToKWh.compareTo(b.upToKWh));

    final double U = unitsKWh;
    double total = 0;
    double start = 0; // Start_i

    for (final tier in tiers) {
      final end = tier.upToKWh; // End_i
      if (end <= start) continue;

      final unitsInSlab = (U <= start)
          ? 0
          : (U >= end)
              ? (end - start)
              : (U - start);

      if (unitsInSlab > 0) {
        total += unitsInSlab * tier.rate;
      }

      start = end;

      if (U <= start) break;
    }

    // Any units above the highest tier form an additional slab
    // with Start_last = last tier end, End_last = U, Rate_last = baseRate.
    if (U > start) {
      final extraUnits = U - start;
      total += extraUnits * tariff.baseRate;
    }

    return total;
  }
}

