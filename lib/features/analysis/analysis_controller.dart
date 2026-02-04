import '../../data/models/appliance_model.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/tariff_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/billing_result.dart';
import '../../logic/billing/slab_model.dart';
import '../../logic/calculator/carbon_calculator.dart';
import '../../logic/calculator/energy_calculator.dart';
import '../../logic/insights/recommendation_engine.dart';
import '../../logic/wastage/wastage_detector.dart';

class ApplianceBreakdown {
  final ApplianceModel appliance;
  final double estimatedKWh;
  final double normalizedKWh;
  final double monthlyCost;
  final double wastageCost;

  const ApplianceBreakdown({
    required this.appliance,
    required this.estimatedKWh,
    required this.normalizedKWh,
    required this.monthlyCost,
    required this.wastageCost,
  });
}

class AnalysisResult {
  final BillModel bill;
  final BillingResult billing;
  final List<ApplianceBreakdown> breakdown;
  final List<ApplianceBreakdown> topConsumers;
  final double totalEstimatedKWh;
  final double wastageKWh;
  final double wastageCost;
  final double savingsLowKWh;
  final double savingsHighKWh;
  final double savingsLowCost;
  final double savingsHighCost;
  final double co2KgCurrent;
  final double co2KgLow;
  final double co2KgHigh;
  final List<Recommendation> recommendations;

  const AnalysisResult({
    required this.bill,
    required this.billing,
    required this.breakdown,
    required this.topConsumers,
    required this.totalEstimatedKWh,
    required this.wastageKWh,
    required this.wastageCost,
    required this.savingsLowKWh,
    required this.savingsHighKWh,
    required this.savingsLowCost,
    required this.savingsHighCost,
    required this.co2KgCurrent,
    required this.co2KgLow,
    required this.co2KgHigh,
    required this.recommendations,
  });
}

class AnalysisController {
  AnalysisResult compute({
    required BillModel bill,
    required List<ApplianceModel> appliances,
    required TariffModel tariff,
    required String connectionType,
  }) {
    final type = connectionTypeFromString(connectionType);
    final billing = BillingEngine().calculateBill(
      connectionType: type,
      units: bill.unitsConsumed,
    );

    final totalEstimated = EnergyCalculator.totalApplianceKWh(appliances);
    final scale = totalEstimated > 0 ? (bill.unitsConsumed / totalEstimated) : 0.0;
    final effectiveRate = billing.effectiveRatePerUnit;

    final wastage = WastageDetector.detect(billUnitsKWh: bill.unitsConsumed, appliances: appliances);
    final wastageCost = wastage.unaccountedKWh * effectiveRate;

    final breakdown = appliances.map((a) {
      final singleEstimatedKWh =
          EnergyCalculator.monthlyKWh(powerWatts: a.powerRating, dailyHours: a.dailyHours);
      final estimatedKWh = a.count <= 0 ? 0.0 : a.count * singleEstimatedKWh;
      final normalizedKWh = estimatedKWh * scale;
      final monthlyCost = normalizedKWh * effectiveRate;

      final extraKWh = wastage.perApplianceExtraKWh[a.applianceId] ?? 0;
      final applianceWastageCost = extraKWh * effectiveRate;

      return ApplianceBreakdown(
        appliance: a,
        estimatedKWh: estimatedKWh,
        normalizedKWh: normalizedKWh,
        monthlyCost: monthlyCost,
        wastageCost: applianceWastageCost,
      );
    }).toList()
      ..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));

    final top = breakdown.take(3).toList();

    // 10–15% savings based on bill units.
    const lowPct = RecommendationEngine.savingsLow;
    const highPct = RecommendationEngine.savingsHigh;
    final savingsLowKWh = bill.unitsConsumed * lowPct;
    final savingsHighKWh = bill.unitsConsumed * highPct;
    final savingsLowCost = savingsLowKWh * effectiveRate;
    final savingsHighCost = savingsHighKWh * effectiveRate;

    final co2Current = CarbonCalculator.kgCO2(bill.unitsConsumed);
    final co2Low = CarbonCalculator.kgCO2(savingsLowKWh);
    final co2High = CarbonCalculator.kgCO2(savingsHighKWh);

    return AnalysisResult(
      bill: bill,
      breakdown: breakdown,
      topConsumers: top,
      totalEstimatedKWh: totalEstimated,
      wastageKWh: wastage.unaccountedKWh,
      wastageCost: wastageCost,
      savingsLowKWh: savingsLowKWh,
      savingsHighKWh: savingsHighKWh,
      savingsLowCost: savingsLowCost,
      savingsHighCost: savingsHighCost,
      co2KgCurrent: co2Current,
      co2KgLow: co2Low,
      co2KgHigh: co2High,
      recommendations: RecommendationEngine.forTopAppliances(top.map((e) => e.appliance).toList()),
      billing: billing,
    );
  }
}


