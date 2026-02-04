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

class BillingResult {
  final ConnectionType connectionType;
  final num totalUnits;
  final num totalBill;
  final num effectiveRatePerUnit;
  final List<SlabCharge> slabCharges;

  /// Optional narrative: how much could be saved by staying in a lower slab.
  final num savingsOpportunityAmount;

  const BillingResult({
    required this.connectionType,
    required this.totalUnits,
    required this.totalBill,
    required this.effectiveRatePerUnit,
    required this.slabCharges,
    required this.savingsOpportunityAmount,
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
      };
}

