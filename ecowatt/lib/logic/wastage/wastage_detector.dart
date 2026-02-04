import '../../data/models/appliance_model.dart';
import '../calculator/energy_calculator.dart';

class WastageResult {
  final double unaccountedKWh;
  final Map<String, double> perApplianceExtraKWh;

  const WastageResult({
    required this.unaccountedKWh,
    required this.perApplianceExtraKWh,
  });
}

/// Detects wastage/unaccounted energy by comparing the actual bill units
/// against calculated appliance energy totals.
class WastageDetector {
  /// If bill units > sum(appliance estimate), difference is considered "unaccounted".
  /// We distribute that difference across appliances proportional to their share,
  /// so each appliance can show a wastage amount for UX.
  static WastageResult detect({
    required double billUnitsKWh,
    required List<ApplianceModel> appliances,
    int days = 30,
  }) {
    final totalEstimated = EnergyCalculator.totalApplianceKWh(appliances, days: days);
    final unaccounted = (billUnitsKWh - totalEstimated);
    if (unaccounted <= 0 || appliances.isEmpty || totalEstimated <= 0) {
      return const WastageResult(unaccountedKWh: 0, perApplianceExtraKWh: {});
    }

    final map = <String, double>{};
    for (final a in appliances) {
      final akwh = EnergyCalculator.monthlyKWh(
        powerWatts: a.powerRating,
        dailyHours: a.dailyHours,
        days: days,
      );
      final share = akwh / totalEstimated;
      map[a.applianceId] = unaccounted * share;
    }

    return WastageResult(unaccountedKWh: unaccounted, perApplianceExtraKWh: map);
  }
}

