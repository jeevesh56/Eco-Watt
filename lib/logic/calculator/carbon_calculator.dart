/// Carbon awareness calculations.
/// Uses a simple region-average emission factor (kg CO2 / kWh).
class CarbonCalculator {
  /// Default ~0.82 kg CO2/kWh (approximate, varies by grid mix).
  static const double defaultKgPerKwh = 0.82;

  static double kgCO2(double unitsKWh, {double kgPerKwh = defaultKgPerKwh}) {
    if (unitsKWh <= 0) return 0;
    return unitsKWh * kgPerKwh;
  }
}

