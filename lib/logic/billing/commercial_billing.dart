import 'billing_result.dart';
import 'slab_model.dart';

/// Commercial billing – non-subsidised, higher-rate, possible fixed charges.
BillingResult calculateCommercialBill({
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

    // Same slab-span logic as residential billing.
    final slabSpan = i == 0 ? (end - start) : (end - start + 1.0);
    final eligibleUnits = (remaining < slabSpan) ? remaining : slabSpan;
    final amount = eligibleUnits * slab.ratePerUnit;

    charges.add(SlabCharge(
      slab: slab,
      unitsInSlab: eligibleUnits.toDouble(),
      amount: amount.toDouble(),
    ));

    total += amount;
    remaining -= eligibleUnits;
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

