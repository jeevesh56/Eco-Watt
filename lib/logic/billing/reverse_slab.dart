import 'slab_model.dart';
import 'tariff_provider.dart';

/// Convert a total slab-billed cost back into approximate units.
///
/// This mirrors the forward slab model in [TariffProvider.profileFor] and the
/// residential billing logic. It is intentionally rule-based – no average
/// rates or flat multipliers are used.
double costToUnitsForConnection({
  required ConnectionType connectionType,
  required double totalCost,
}) {
  final profile = TariffProvider.profileFor(connectionType);
  return costToUnitsForProfile(profile: profile, totalCost: totalCost);
}

double costToUnitsForProfile({
  required TariffProfile profile,
  required double totalCost,
}) {
  final slabs = profile.slabs;
  if (slabs.isEmpty) return 0;

  double remaining = totalCost - profile.fixedCharge.toDouble();
  if (remaining < 0) remaining = 0;
  double units = 0;

  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    final isFirst = i == 0;
    final isLast = i == slabs.length - 1;

    // Span logic must mirror the forward billing implementation:
    // first slab uses (end - start), later slabs use (end - start + 1).
    final span = isFirst
        ? (slab.endInclusive - slab.startInclusive)
        : (slab.endInclusive - slab.startInclusive + 1.0);
    final rate = slab.ratePerUnit;

    // First subsidised slab: always grant full span of units.
    if (isFirst && rate == 0) {
      units += span;
      continue;
    }

    if (rate <= 0) {
      continue;
    }

    if (isLast) {
      // Highest slab: any remaining cost is billed at this rate.
      units += remaining / rate;
      return units;
    }

    final slabCost = span * rate;
    if (remaining >= slabCost) {
      units += span;
      remaining -= slabCost;
    } else {
      units += remaining / rate;
      return units;
    }
  }

  return units;
}

