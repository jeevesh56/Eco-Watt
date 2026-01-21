import '../../data/models/bill_model.dart';

enum TrendStatus { increase, decrease, stable }

class BillTrend {
  final BillModel bill;
  final TrendStatus status;
  final double percentChange; // vs previous month

  const BillTrend({
    required this.bill,
    required this.status,
    required this.percentChange,
  });
}

class HistoryController {
  List<BillTrend> buildTrends(List<BillModel> bills) {
    if (bills.isEmpty) return const [];
    final sorted = bills.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final trends = <BillTrend>[];
    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = i > 0 ? sorted[i - 1] : null;
      trends.add(trendFor(current, previous));
    }
    return trends;
  }

  /// Month-to-month percent change based on units (primary), with stable threshold 2%.
  static BillTrend trendFor(BillModel current, BillModel? previous) {
    if (previous == null || previous.unitsConsumed <= 0) {
      return BillTrend(bill: current, status: TrendStatus.stable, percentChange: 0);
    }
    final diff = current.unitsConsumed - previous.unitsConsumed;
    final pct = (diff / previous.unitsConsumed) * 100.0;
    final abs = pct.abs();
    if (abs < 2.0) {
      return BillTrend(bill: current, status: TrendStatus.stable, percentChange: pct);
    }
    return BillTrend(
      bill: current,
      status: pct > 0 ? TrendStatus.increase : TrendStatus.decrease,
      percentChange: pct,
    );
  }
}

