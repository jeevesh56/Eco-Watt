class UserModel {
  final String userId;
  /// Electricity connection type: 'residential' or 'commercial'.
  final String connectionType;
  final int occupants;
  final String currency;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.userId,
    required this.connectionType,
    required this.occupants,
    required this.currency,
    required this.preferences,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'connectionType': connectionType,
        'occupants': occupants,
        'currency': currency,
        'preferences': preferences,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: (json['userId'] as String?) ?? '',
        // Backwards-compat: read legacy 'homeType' if present.
        connectionType: (json['connectionType'] as String?) ??
            (json['homeType'] as String?) ??
            'residential',
        occupants: (json['occupants'] as num?)?.toInt() ?? 1,
        currency: (json['currency'] as String?) ?? '₹',
        preferences:
            (json['preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
