import 'package:flutter_test/flutter_test.dart';
import 'package:ecowatt/logic/calculator/energy_calculator.dart';
import 'package:ecowatt/logic/calculator/cost_calculator.dart';
import 'package:ecowatt/data/models/tariff_model.dart';
import 'package:ecowatt/logic/wastage/wastage_detector.dart';
import 'package:ecowatt/data/models/appliance_model.dart';

void main() {
  test('monthlyKWh computes correctly', () {
    // 1000W for 2 hours/day over 30 days = (1000/1000)*2*30 = 60 kWh
    final kwh = EnergyCalculator.monthlyKWh(powerWatts: 1000, dailyHours: 2, days: 30);
    expect(kwh, closeTo(60.0, 0.001));
  });

  test('costForUnits uses base rate without tiers', () {
    final tariff = TariffModel(providerName: 'T', baseRate: 5.0, tieredPricing: const [], currency: '₹');
    final cost = CostCalculator.costForUnits(100, tariff);
    expect(cost, 500);
  });

  test('wastage detector distributes unaccounted kWh', () {
    final apps = [
      ApplianceModel(applianceId: 'a1', name: 'A', powerRating: 100, usageLevel: 'medium', dailyHours: 5, starRating: 3, monthlyCost: 0, wastageAmount: 0),
      ApplianceModel(applianceId: 'a2', name: 'B', powerRating: 200, usageLevel: 'medium', dailyHours: 5, starRating: 3, monthlyCost: 0, wastageAmount: 0),
    ];
    // Estimated: A = (100/1000)*5*30 = 15kWh, B = (200/1000)*5*30 = 30kWh => total = 45
    // Bill says 60 => unaccounted = 15. Shares: A=1/3, B=2/3 => A=5, B=10
    final res = WastageDetector.detect(billUnitsKWh: 60, appliances: apps);
    expect(res.unaccountedKWh, closeTo(15.0, 0.001));
    expect(res.perApplianceExtraKWh['a1'], closeTo(5.0, 0.01));
    expect(res.perApplianceExtraKWh['a2'], closeTo(10.0, 0.01));
  });
}


