import 'dart:math';

import 'billing_result.dart';
import 'slab_model.dart';

/// Residential billing with slab-based subsidy.
/// Uses formula: Units_i = max(0, min(U, End_i) - Start_i), Cost_i = Units_i × Rate_i, Total = Σ Cost_i
BillingResult calculateResidentialBill({
  required TariffProfile profile,
  required double units,
}) {
  final slabs = profile.slabs;
  final charges = <SlabCharge>[];
  double total = profile.fixedCharge.toDouble();

  for (final slab in slabs) {
    final start = slab.startInclusive;
    final end = slab.endInclusive;
    
    // Units_i = max(0, min(U, End_i) - Start_i)
    // For inclusive ranges [Start_i, End_i], add 1 to account for inclusive end
    final unitsInSlab = units >= start
        ? (min(units, end) - start + 1.0).clamp(0.0, double.infinity)
        : 0.0;
    
    // Cost_i = Units_i × Rate_i (or 0 if subsidised)
    final amount = slab.isSubsidised ? 0.0 : unitsInSlab * slab.ratePerUnit;
    
    if (unitsInSlab > 0) {
      charges.add(SlabCharge(
        slab: slab,
        unitsInSlab: unitsInSlab,
        amount: amount,
      ));
    }
    
    // Total Bill = Σ Cost_i
    total += amount;
  }

  final effectiveRate = units > 0 ? total / units : 0;

  // Savings opportunity: if user stayed within the second slab bound.
  double savings = 0;
  if (units > 0 && slabs.length >= 2) {
    final second = slabs[1];
    final threshold = second.endInclusive;
    if (units > threshold) {
      final extraUnits = units - threshold;
      savings = extraUnits * second.ratePerUnit;
    }
  }

  return BillingResult(
    connectionType: profile.connectionType,
    totalUnits: units,
    totalBill: total,
    effectiveRatePerUnit: effectiveRate,
    slabCharges: charges,
    savingsOpportunityAmount: savings,
    slabProgress: deriveSlabProgress(slabs: slabs, units: units),
  );
}

