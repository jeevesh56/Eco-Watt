import '../../data/models/appliance_model.dart';

class ApplianceDetailResult {
  final double estimatedMonthlyKWh;
  final double monthlyCost;
  final double wastageCost;
  final String wastageReason;
  final List<String> optimizationTips;
  final int recommendedStar;
  final double replacementMonthlySavings;

  const ApplianceDetailResult({
    required this.estimatedMonthlyKWh,
    required this.monthlyCost,
    required this.wastageCost,
    required this.wastageReason,
    required this.optimizationTips,
    required this.recommendedStar,
    required this.replacementMonthlySavings,
  });
}

class ApplianceDetailController {
  /// Heuristic: each star improvement saves ~8% energy.
  static const double starSavingsPerLevel = 0.08;

  ApplianceDetailResult compute({
    required ApplianceModel appliance,
    required double effectiveRate,
    required double normalizedMonthlyKWh,
    required double wastageCost,
  }) {
    final reason = _reason(appliance, wastageCost);
    final tips = _tipsFor(appliance);
    final targetStar = (appliance.starRating + 2).clamp(1, 5);
    final deltaStars = (targetStar - appliance.starRating).clamp(0, 4);
    final replacementSavings = (normalizedMonthlyKWh * effectiveRate) * (deltaStars * starSavingsPerLevel);

    return ApplianceDetailResult(
      estimatedMonthlyKWh: normalizedMonthlyKWh,
      monthlyCost: normalizedMonthlyKWh * effectiveRate,
      wastageCost: wastageCost,
      wastageReason: reason,
      optimizationTips: tips,
      recommendedStar: targetStar,
      replacementMonthlySavings: replacementSavings,
    );
  }

  String _reason(ApplianceModel a, double wastageCost) {
    if (wastageCost <= 0.01) return 'No significant wastage detected for this appliance.';
    if (a.usageLevel == 'high') return 'Usage pattern: high daily hours increases energy use and wastage risk.';
    if (a.starRating <= 2) return 'Inefficiency: low star rating typically consumes more energy for the same output.';
    return 'Unaccounted loads: standby losses or hidden consumption may contribute to wastage.';
  }

  List<String> _tipsFor(ApplianceModel a) {
    switch (a.name.toLowerCase()) {
      case 'air conditioner':
        return const [
          'Clean filters monthly to improve airflow and reduce compressor load.',
          'Set 24–26°C to cut power draw without losing comfort.',
          'Close doors/windows to prevent cool air leakage.',
        ];
      case 'refrigerator':
        return const [
          'Keep the back ventilated and clean condenser coils.',
          'Avoid frequent door opening; check gasket sealing.',
          'Do not overfill; allow airflow inside.',
        ];
      case 'washing machine':
        return const [
          'Wash full loads instead of many small cycles.',
          'Use cold-water cycles when possible.',
          'Clean filter and ensure balanced loads.',
        ];
      case 'tv':
        return const [
          'Reduce brightness and enable eco mode.',
          'Turn off fully (avoid standby) when not in use.',
          'Limit background TV usage.',
        ];
      case 'light':
        return const [
          'Use daylight when possible.',
          'Turn off lights in empty rooms.',
          'Use efficient bulbs where available.',
        ];
      case 'fan':
        return const [
          'Use only in occupied rooms.',
          'Lower speed when comfortable.',
          'Clean blades regularly for smoother airflow.',
        ];
      default:
        return const [
          'Reduce daily usage time.',
          'Turn off fully when not needed.',
          'Maintain and clean regularly for efficiency.',
        ];
    }
  }
}


