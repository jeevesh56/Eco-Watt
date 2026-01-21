class TariffModel {
  final String providerName;
  final double baseRate;
  final List<TariffTierModel> tieredPricing;
  final String currency;

  const TariffModel({
    required this.providerName,
    required this.baseRate,
    required this.tieredPricing,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
        'providerName': providerName,
        'baseRate': baseRate,
        'tieredPricing': tieredPricing.map((e) => e.toJson()).toList(),
        'currency': currency,
      };

  factory TariffModel.fromJson(Map<String, dynamic> json) => TariffModel(
        providerName: (json['providerName'] as String?) ?? 'Default',
        baseRate: (json['baseRate'] as num?)?.toDouble() ?? 8.0,
        tieredPricing: ((json['tieredPricing'] as List?) ?? const [])
            .map(
              (e) => TariffTierModel.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
        currency: (json['currency'] as String?) ?? '₹',
      );
}

class TariffTierModel {
  final double upToKWh;
  final double rate;

  const TariffTierModel({required this.upToKWh, required this.rate});

  Map<String, dynamic> toJson() => {
        'upToKWh': upToKWh,
        'rate': rate,
      };

  factory TariffTierModel.fromJson(Map<String, dynamic> json) => TariffTierModel(
        upToKWh: (json['upToKWh'] as num?)?.toDouble() ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
      );
}

