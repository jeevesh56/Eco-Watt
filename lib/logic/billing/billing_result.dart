import 'slab_model.dart';

/// Result of a billing calculation for a single bill.
class SlabCharge {
  final Slab slab;
  final double unitsInSlab;
  final double amount;

  const SlabCharge({
    required this.slab,
    required this.unitsInSlab,
    required this.amount,
  });
}

class SlabProgress {
  /// Total units used in the current billing calculation.
  final double currentUnits;

  /// Inclusive start of the current slab the user is in.
  final double currentSlabStart;

  /// Inclusive end (upper bound) of the current slab.
  final double currentSlabLimit;

  /// Inclusive end of the next slab; null if already on the highest slab.
  final double? nextSlabLimit;

  /// Units left in the current slab (currentSlabLimit - currentUnits).
  final double unitsLeftInSlab;

  const SlabProgress({
    required this.currentUnits,
    required this.currentSlabStart,
    required this.currentSlabLimit,
    required this.nextSlabLimit,
    required this.unitsLeftInSlab,
  });

  /// Units remaining before hitting the next slab. Null when no next slab exists.
  double? get unitsToNextSlab =>
      nextSlabLimit == null ? null : (nextSlabLimit! - currentUnits);

  Map<String, dynamic> toJson() => {
        'currentUnits': currentUnits,
        'currentSlabStart': currentSlabStart,
        'currentSlabLimit': currentSlabLimit,
        'nextSlabLimit': nextSlabLimit,
        'unitsLeftInSlab': unitsLeftInSlab,
      };
}

class BillingResult {
  final ConnectionType connectionType;
  final num totalUnits;
  final num totalBill;
  final num effectiveRatePerUnit;
  final List<SlabCharge> slabCharges;

  /// Optional narrative: how much could be saved by staying in a lower slab.
  final num savingsOpportunityAmount;

  /// Snapshot of the user's position within the slab structure.
  final SlabProgress slabProgress;

  const BillingResult({
    required this.connectionType,
    required this.totalUnits,
    required this.totalBill,
    required this.effectiveRatePerUnit,
    required this.slabCharges,
    required this.savingsOpportunityAmount,
    required this.slabProgress,
  });

  Map<String, dynamic> toJson() => {
        'connectionType': connectionTypeToString(connectionType),
        'totalUnits': totalUnits,
        'totalBill': totalBill,
        'effectiveRatePerUnit': effectiveRatePerUnit,
        'slabCharges': slabCharges
            .map((s) => {
                  'start': s.slab.startInclusive,
                  'end': s.slab.endInclusive,
                  'rate': s.slab.ratePerUnit,
                  'isSubsidised': s.slab.isSubsidised,
                  'unitsInSlab': s.unitsInSlab,
                  'amount': s.amount,
                })
            .toList(),
        'savingsOpportunityAmount': savingsOpportunityAmount,
        'slabProgress': slabProgress.toJson(),
      };
}

/// Calculate cost for specific units using the same billing logic.
/// Uses inclusive formula: Units_i = max(0, min(units, slab.end) - slab.start + 1)
double _calculateCostForUnits({
  required List<Slab> slabs,
  required double units,
  required double fixedCharge,
}) {
  double total = fixedCharge;

  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    final start = slab.startInclusive;
    final end = slab.endInclusive;
    
    if (units < start) continue;
    
    final unitsInSlab = units <= end
        ? (units - start + 1.0).clamp(0.0, double.infinity)
        : (end - start + 1.0);
    
    if (unitsInSlab <= 0) continue;

    final amount = slab.isSubsidised ? 0 : unitsInSlab * slab.ratePerUnit;
    total += amount;
  }

  return total;
}

SlabProgress deriveSlabProgress({
  required List<Slab> slabs,
  required double units,
}) {
  if (slabs.isEmpty) {
    return const SlabProgress(
      currentUnits: 0,
      currentSlabStart: 0,
      currentSlabLimit: 0,
      nextSlabLimit: null,
      unitsLeftInSlab: 0,
    );
  }

  final clampedUnits = units < 0 ? 0.0 : units;
  Slab current = slabs.last; // Default to highest slab if units exceed all
  Slab? next;

  // Find the current slab: units >= slab.start AND units <= slab.end
  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    final isCurrent = clampedUnits >= slab.startInclusive &&
        clampedUnits <= slab.endInclusive;
    if (isCurrent) {
      current = slab;
      if (i + 1 < slabs.length) {
        next = slabs[i + 1];
      }
      break;
    }
    // If units exceed this slab but haven't found current yet, continue
    if (clampedUnits > slab.endInclusive && i == slabs.length - 1) {
      // Units exceed all slabs, use highest slab
      current = slab;
      next = null;
    }
  }

  // Current slab end is always the slab's endInclusive (not clamped to units)
  final double currentSlabEnd = current.endInclusive;
  
  // Calculate units left in current slab
  final unitsLeftInSlab = (currentSlabEnd - clampedUnits).clamp(0.0, double.infinity);

  return SlabProgress(
    currentUnits: clampedUnits,
    currentSlabStart: current.startInclusive,
    currentSlabLimit: currentSlabEnd,
    nextSlabLimit: next?.endInclusive,
    unitsLeftInSlab: unitsLeftInSlab,
  );
}

