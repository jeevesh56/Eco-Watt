import 'dart:math';

import 'billing_result.dart';
import 'slab_model.dart';

/// Commercial billing – non-subsidised, higher-rate, possible fixed charges.
/// Uses formula: Units_i = max(0, min(U, End_i) - Start_i), Cost_i = Units_i × Rate_i, Total = Σ Cost_i
BillingResult calculateCommercialBill({
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
    
    // Cost_i = Units_i × Rate_i
    final amount = unitsInSlab * slab.ratePerUnit;
    
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

  // For commercial, savings insight is simpler: reducing usage directly
  // reduces cost; we express an indicative 10% reduction potential in rupees.
  final savings = (units * 0.10) * effectiveRate;

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

