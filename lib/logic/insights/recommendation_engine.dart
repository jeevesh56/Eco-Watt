import '../../data/models/appliance_model.dart';

class Recommendation {
  final String title;
  final String detail;
  final double? estimatedMonthlySavingsPct;

  const Recommendation({
    required this.title,
    required this.detail,
    this.estimatedMonthlySavingsPct,
  });
}

/// Produces actionable recommendations. Keep heuristics here (not in UI).
class RecommendationEngine {
  /// 10–15% generic savings estimate required by spec.
  static const savingsLow = 0.10;
  static const savingsHigh = 0.15;

  static List<Recommendation> forTopAppliances(List<ApplianceModel> top) {
    final recs = <Recommendation>[
      const Recommendation(
        title: 'Avoid standby wastage',
        detail: 'Turn off appliances fully when not in use and unplug chargers to reduce idle consumption.',
        estimatedMonthlySavingsPct: 0.02,
      ),
    ];

    for (final a in top) {
      switch (a.name.toLowerCase()) {
        case 'air conditioner':
          recs.add(const Recommendation(
            title: 'Optimize AC usage',
            detail: 'Set 24–26°C, clean filters, and close doors/windows to reduce compressor load.',
            estimatedMonthlySavingsPct: 0.06,
          ));
          break;
        case 'refrigerator':
          recs.add(const Recommendation(
            title: 'Improve refrigerator efficiency',
            detail: 'Keep ventilation space behind, avoid frequent door opening, and check door gasket sealing.',
            estimatedMonthlySavingsPct: 0.03,
          ));
          break;
        case 'washing machine':
          recs.add(const Recommendation(
            title: 'Smarter laundry cycles',
            detail: 'Wash full loads and prefer cold-water cycles when possible to cut energy use.',
            estimatedMonthlySavingsPct: 0.03,
          ));
          break;
        case 'tv':
          recs.add(const Recommendation(
            title: 'Reduce TV energy',
            detail: 'Lower brightness and disable always-on features; avoid background usage.',
            estimatedMonthlySavingsPct: 0.02,
          ));
          break;
        case 'light':
          recs.add(const Recommendation(
            title: 'Lighting efficiency',
            detail: 'Use daylight, switch off unused lights, and consider efficient bulbs where possible.',
            estimatedMonthlySavingsPct: 0.02,
          ));
          break;
        case 'fan':
          recs.add(const Recommendation(
            title: 'Fan usage tuning',
            detail: 'Use only in occupied rooms and reduce speed when comfortable.',
            estimatedMonthlySavingsPct: 0.02,
          ));
          break;
        default:
          recs.add(Recommendation(
            title: 'Reduce ${a.name} usage time',
            detail: 'Lower daily hours or intensity to cut monthly consumption.',
            estimatedMonthlySavingsPct: 0.03,
          ));
      }
    }

    return recs.take(3).toList();
  }
}

