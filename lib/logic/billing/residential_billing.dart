import 'billing_result.dart';
import 'slab_model.dart';

/// Residential billing with slab-based subsidy.
/// 
/// Uses inclusive formula: Units_i = max(0, min(units, slab.end) - slab.start + 1)
BillingResult calculateResidentialBill({
  required TariffProfile profile,
  required double units,
}) {
  final slabs = profile.slabs;
  final charges = <SlabCharge>[];
  double total = profile.fixedCharge.toDouble();

  // Calculate units and cost for each slab using inclusive formula
  // Cumulative billing: charge for all units up to current consumption
  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    final start = slab.startInclusive;
    final end = slab.endInclusive;
    
    // Skip slabs that haven't been reached
    if (units < start) continue;
    
    // Inclusive formula: Units_i = max(0, min(units, slab.end) - slab.start + 1)
    // If units fall within this slab: units - start + 1
    // If units exceed this slab: end - start + 1 (full slab)
    final unitsInSlab = units <= end
        ? (units - start + 1.0).clamp(0.0, double.infinity)
        : (end - start + 1.0);
    
    if (unitsInSlab <= 0) continue;

    final amount = slab.isSubsidised ? 0 : unitsInSlab * slab.ratePerUnit;
    charges.add(SlabCharge(
      slab: slab,
      unitsInSlab: unitsInSlab,
      amount: amount.toDouble(),
    ));

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

