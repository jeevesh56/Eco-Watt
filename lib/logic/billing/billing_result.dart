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

  const SlabProgress({
    required this.currentUnits,
    required this.currentSlabStart,
    required this.currentSlabLimit,
    required this.nextSlabLimit,
  });

  /// Units remaining before hitting the next slab. Null when no next slab exists.
  double? get unitsToNextSlab =>
      nextSlabLimit == null ? null : (nextSlabLimit! - currentUnits);

  Map<String, dynamic> toJson() => {
        'currentUnits': currentUnits,
        'currentSlabStart': currentSlabStart,
        'currentSlabLimit': currentSlabLimit,
        'nextSlabLimit': nextSlabLimit,
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

/// Finds current slab from table ranges — NEVER derive from units.
/// currentSlab = slabs.find(s => units >= s.start && units <= s.end)
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
    );
  }

  final clampedUnits = units < 0 ? 0.0 : units;
  Slab current = slabs.first;
  Slab? next;

  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    if (clampedUnits >= slab.startInclusive &&
        clampedUnits <= slab.endInclusive) {
      current = slab;
      if (i + 1 < slabs.length) {
        next = slabs[i + 1];
      }
      break;
    }
    if (i == slabs.length - 1) {
      current = slab;
    }
  }

  // ALWAYS use slab boundaries — never set currentSlabLimit = units
  return SlabProgress(
    currentUnits: clampedUnits,
    currentSlabStart: current.startInclusive,
    currentSlabLimit: current.endInclusive,
    nextSlabLimit: next?.endInclusive,
  );
}

