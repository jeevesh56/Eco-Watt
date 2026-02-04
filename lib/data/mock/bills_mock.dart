import '../models/bill_model.dart';

class BillsMock {
  static List<BillModel> seed() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      final units = 180 + (i * 12);
      final amount = units * 8.0;
      return BillModel(
        billId: '${d.year}-${d.month}',
        month: d.month,
        year: d.year,
        unitsConsumed: units.toDouble(),
        billAmount: amount.toDouble(),
        calculatedBreakdown: const {},
        createdAt: d,
      );
    }).reversed.toList();
  }
}

