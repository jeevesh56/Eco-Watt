class BillModel {
  final String billId;
  final int month;
  final int year;
  final double unitsConsumed;
  final double billAmount;
  final Map<String, dynamic> calculatedBreakdown;
  final DateTime createdAt;

  const BillModel({
    required this.billId,
    required this.month,
    required this.year,
    required this.unitsConsumed,
    required this.billAmount,
    required this.calculatedBreakdown,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'billId': billId,
        'month': month,
        'year': year,
        'unitsConsumed': unitsConsumed,
        'billAmount': billAmount,
        'calculatedBreakdown': calculatedBreakdown,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
        billId: (json['billId'] as String?) ?? '',
        month: (json['month'] as num?)?.toInt() ?? 1,
        year: (json['year'] as num?)?.toInt() ?? 2026,
        unitsConsumed: (json['unitsConsumed'] as num?)?.toDouble() ?? 0,
        billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0,
        calculatedBreakdown:
            (json['calculatedBreakdown'] as Map?)?.cast<String, dynamic>() ??
                const {},
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}

