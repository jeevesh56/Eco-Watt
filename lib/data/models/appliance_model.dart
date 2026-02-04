class ApplianceModel {
  final String applianceId;
  final String name;
  final double powerRating; // watts
  final String usageLevel; // low/medium/high
  final double dailyHours;
  final int starRating;
  final int count; // how many identical units
  final String category; // e.g. Lighting, Cooling, Entertainment

  /// Calculated fields are persisted for offline UX, but are derived from logic.
  final double monthlyCost;
  final double wastageAmount;

  const ApplianceModel({
    required this.applianceId,
    required this.name,
    required this.powerRating,
    required this.usageLevel,
    required this.dailyHours,
    required this.starRating,
    required this.count,
    required this.category,
    required this.monthlyCost,
    required this.wastageAmount,
  });

  Map<String, dynamic> toJson() => {
        'applianceId': applianceId,
        'name': name,
        'powerRating': powerRating,
        'usageLevel': usageLevel,
        'dailyHours': dailyHours,
        'starRating': starRating,
        'count': count,
        'category': category,
        'monthlyCost': monthlyCost,
        'wastageAmount': wastageAmount,
      };

  factory ApplianceModel.fromJson(Map<String, dynamic> json) => ApplianceModel(
        applianceId: (json['applianceId'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        powerRating: (json['powerRating'] as num?)?.toDouble() ?? 0,
        usageLevel: (json['usageLevel'] as String?) ?? 'medium',
        dailyHours: (json['dailyHours'] as num?)?.toDouble() ?? 5,
        starRating: (json['starRating'] as num?)?.toInt() ?? 3,
        count: (json['count'] as num?)?.toInt() ?? 1,
        category: (json['category'] as String?) ?? 'General',
        monthlyCost: (json['monthlyCost'] as num?)?.toDouble() ?? 0,
        wastageAmount: (json['wastageAmount'] as num?)?.toDouble() ?? 0,
      );

  ApplianceModel copyWith({
    String? applianceId,
    String? name,
    double? powerRating,
    String? usageLevel,
    double? dailyHours,
    int? starRating,
    int? count,
    String? category,
    double? monthlyCost,
    double? wastageAmount,
  }) {
    return ApplianceModel(
      applianceId: applianceId ?? this.applianceId,
      name: name ?? this.name,
      powerRating: powerRating ?? this.powerRating,
      usageLevel: usageLevel ?? this.usageLevel,
      dailyHours: dailyHours ?? this.dailyHours,
      starRating: starRating ?? this.starRating,
      count: count ?? this.count,
      category: category ?? this.category,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      wastageAmount: wastageAmount ?? this.wastageAmount,
    );
  }
}

