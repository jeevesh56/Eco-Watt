class ApplianceModel {
  final String applianceId;
  final String name;
  final double powerRating; // watts
  final String usageLevel; // low/medium/high
  final double dailyHours;
  final int starRating;

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
      monthlyCost: monthlyCost ?? this.monthlyCost,
      wastageAmount: wastageAmount ?? this.wastageAmount,
    );
  }
}

