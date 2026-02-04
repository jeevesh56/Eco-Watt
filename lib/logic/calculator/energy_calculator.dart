import '../../data/models/appliance_model.dart';

/// All energy calculations must live in /logic.
class EnergyCalculator {
  /// Monthly kWh = (W / 1000) * hours/day * days
  static double monthlyKWh({
    required double powerWatts,
    required double dailyHours,
    int days = 30,
  }) {
    return (powerWatts / 1000.0) * dailyHours * days;
  }

  static double totalApplianceKWh(List<ApplianceModel> appliances, {int days = 30}) {
    return appliances.fold<double>(
      0,
      (sum, a) =>
          sum +
          (a.count <= 0
              ? 0
              : a.count *
                  monthlyKWh(
                    powerWatts: a.powerRating,
                    dailyHours: a.dailyHours,
                    days: days,
                  )),
    );
  }
}

