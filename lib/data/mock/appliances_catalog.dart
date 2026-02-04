import '../models/appliance_model.dart';

/// Central catalog of supported appliances and their default power ratings.
/// Per requirements, appliance power values live under /data (not UI).
class AppliancesCatalog {
  static const List<_CatalogItem> _items = [
    _CatalogItem(name: 'Fan', watts: 75, category: 'Cooling'),
    _CatalogItem(name: 'Light', watts: 20, category: 'Lighting'),
    _CatalogItem(name: 'TV', watts: 150, category: 'Entertainment'),
    _CatalogItem(name: 'Refrigerator', watts: 200, category: 'Kitchen'),
    _CatalogItem(name: 'Washing Machine', watts: 500, category: 'Laundry'),
    _CatalogItem(name: 'Air Conditioner', watts: 1500, category: 'Cooling'),
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
            count: 1,
            category: i.category,
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

  /// Helper for constructing custom appliances from user input.
  static ApplianceModel custom({
    required String name,
    required double powerRating,
    String usageLevel = 'medium',
    int starRating = 3,
    String category = 'Custom',
  }) {
    final hours = usageHours(usageLevel);
    return ApplianceModel(
      applianceId: 'custom_${name}_${powerRating.toStringAsFixed(0)}',
      name: name,
      powerRating: powerRating,
      usageLevel: usageLevel,
      dailyHours: hours,
      starRating: starRating,
      count: 1,
      category: category,
      monthlyCost: 0,
      wastageAmount: 0,
    );
  }
}

class _CatalogItem {
  final String name;
  final double watts;
  final String category;
  const _CatalogItem({required this.name, required this.watts, required this.category});
}

