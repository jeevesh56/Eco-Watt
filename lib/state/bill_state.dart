import 'package:flutter/foundation.dart';

import '../data/models/bill_model.dart';
import '../data/repositories/bill_repository.dart';

class BillState extends ChangeNotifier {
  final BillRepository _repo;

  BillState(this._repo);

  bool _loaded = false;
  bool get loaded => _loaded;

  final List<BillModel> _bills = [];
  List<BillModel> get bills => List.unmodifiable(_bills);

  BillModel? get latest => _bills.isEmpty ? null : _bills.last;

  Future<void> load({required int? userId}) async {
    _bills
      ..clear()
      ..addAll(await _repo.getBills(userId: userId));
    _loaded = true;
    notifyListeners();
  }

  Future<void> addMonthlyBill({
    required int? userId,
    required BillModel bill,
    required String connectionType,
  }) async {
    await _repo.addMonthlyBill(
      userId: userId,
      bill: bill,
      connectionType: connectionType,
    );
    await load(userId: userId);
  }
}

