import 'package:flutter_test/flutter_test.dart';
import 'package:ecowatt/features/analysis/analysis_controller.dart';
import 'package:ecowatt/data/models/bill_model.dart';
import 'package:ecowatt/data/models/appliance_model.dart';
import 'package:ecowatt/data/models/tariff_model.dart';

void main() {
  test('analysis normalization scales appliance kWh to bill units', () {
    final bill = BillModel(
      billId: 'b1',
      month: 1,
      year: 2026,
      unitsConsumed: 100.0,
      billAmount: 500.0,
      calculatedBreakdown: {},
      createdAt: DateTime.now(),
    );

    final apps = [
      ApplianceModel(applianceId: 'a1', name: 'A', powerRating: 100, usageLevel: 'medium', dailyHours: 5, starRating: 3, count: 1, category: 'General', monthlyCost: 0, wastageAmount: 0),
      ApplianceModel(applianceId: 'a2', name: 'B', powerRating: 200, usageLevel: 'medium', dailyHours: 5, starRating: 3, count: 1, category: 'General', monthlyCost: 0, wastageAmount: 0),
    ];

    final tariff = TariffModel(providerName: 'T', baseRate: 5.0, tieredPricing: const [], currency: '₹');

    final result = AnalysisController().compute(bill: bill, appliances: apps, tariff: tariff, connectionType: 'residential');

    final sumNormalized = result.breakdown.fold<double>(0, (s, b) => s + b.normalizedKWh);
    expect(sumNormalized, closeTo(bill.unitsConsumed, 0.001));
  });
}
