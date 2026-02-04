import 'billing_result.dart';
import 'slab_model.dart';

/// Residential billing with slab-based subsidy.
BillingResult calculateResidentialBill({
  required TariffProfile profile,
  required double units,
}) {
  final slabs = profile.slabs;
  final charges = <SlabCharge>[];
  double remaining = units;
  double total = profile.fixedCharge.toDouble();

  for (var i = 0; i < slabs.length; i++) {
    final slab = slabs[i];
    if (remaining <= 0) break;
    final start = slab.startInclusive;
    final end = slab.endInclusive;
    if (units < start) continue;

    // Compute how many units this slab can hold.
    // For the first slab we use (end - start), for later slabs (end - start + 1)
    // so that each slab covers the intended range without off‑by‑one issues.
    final slabSpan = i == 0 ? (end - start) : (end - start + 1.0);
    final eligibleUnits = (remaining < slabSpan) ? remaining : slabSpan;

    final amount = slab.isSubsidised ? 0 : eligibleUnits * slab.ratePerUnit;
    charges.add(SlabCharge(
      slab: slab,
      unitsInSlab: eligibleUnits.toDouble(),
      amount: amount.toDouble(),
    ));

    total += amount;
    remaining -= eligibleUnits;
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

