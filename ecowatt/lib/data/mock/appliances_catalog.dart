import '../models/appliance_model.dart';

/// Central catalog of supported appliances and their default power ratings.
/// Per requirements, appliance power values live under /data (not UI).
class AppliancesCatalog {
  static const List<_CatalogItem> _items = [
    _CatalogItem(name: 'Fan', watts: 75),
    _CatalogItem(name: 'Light', watts: 20),
    _CatalogItem(name: 'TV', watts: 150),
    _CatalogItem(name: 'Refrigerator', watts: 200),
    _CatalogItem(name: 'Washing Machine', watts: 500),
    _CatalogItem(name: 'Air Conditioner', watts: 1500),
  ];

  static List<ApplianceModel> defaults() {
    return _items
        .map(
          (i) => ApplianceModel(
            applianceId: i.name, // stable id for local persistence
            name: i.name,
            powerRating: i.watts,
            usageLevel: 'medium',
            dailyHours: usageHours('medium'),
            starRating: 3,
            monthlyCost: 0,
            wastageAmount: 0,
          ),
        )
        .toList();
  }

  /// Mapping required by spec: Low=2, Medium=5, High=8 hours/day.
  static double usageHours(String usageLevel) {
    switch (usageLevel) {
      case 'low':
        return 2;
      case 'high':
        return 8;
      case 'medium':
      default:
        return 5;
    }
  }
}

class _CatalogItem {
  final String name;
  final double watts;
  const _CatalogItem({required this.name, required this.watts});
}

