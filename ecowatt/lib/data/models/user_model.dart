class UserModel {
  final String userId;
  final String homeType; // apartment/house/villa
  final int occupants;
  final TariffSettings tariffSettings;
  final String currency;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.userId,
    required this.homeType,
    required this.occupants,
    required this.tariffSettings,
    required this.currency,
    required this.preferences,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'homeType': homeType,
        'occupants': occupants,
        'tariffSettings': tariffSettings.toJson(),
        'currency': currency,
        'preferences': preferences,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: (json['userId'] as String?) ?? '',
        homeType: (json['homeType'] as String?) ?? 'apartment',
        occupants: (json['occupants'] as num?)?.toInt() ?? 1,
        tariffSettings: TariffSettings.fromJson(
          (json['tariffSettings'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        currency: (json['currency'] as String?) ?? '₹',
        preferences:
            (json['preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class TariffSettings {
  final String providerName;
  final double baseRate;
  final List<TariffSlab> tieredPricing;

  const TariffSettings({
    required this.providerName,
    required this.baseRate,
    required this.tieredPricing,
  });

  Map<String, dynamic> toJson() => {
        'providerName': providerName,
        'baseRate': baseRate,
        'tieredPricing': tieredPricing.map((e) => e.toJson()).toList(),
      };

  factory TariffSettings.fromJson(Map<String, dynamic> json) => TariffSettings(
        providerName: (json['providerName'] as String?) ?? 'Default',
        baseRate: (json['baseRate'] as num?)?.toDouble() ?? 8.0,
        tieredPricing: ((json['tieredPricing'] as List?) ?? const [])
            .map((e) => TariffSlab.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class TariffSlab {
  final double upToKWh;
  final double rate;

  const TariffSlab({required this.upToKWh, required this.rate});

  Map<String, dynamic> toJson() => {
        'upToKWh': upToKWh,
        'rate': rate,
      };

  factory TariffSlab.fromJson(Map<String, dynamic> json) => TariffSlab(
        upToKWh: (json['upToKWh'] as num?)?.toDouble() ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
      );
}

