import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_model.dart';

class BillRepository {
  String _keyForUser(int userId) => 'ecowatt_bills_user_$userId';

  Future<List<BillModel>> getBills({required int? userId}) async {
    if (userId == null) return [];
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_keyForUser(userId));
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map>();
    return list
        .map((e) => BillModel.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addMonthlyBill({
    required int? userId,
    required BillModel bill,
    required String connectionType,
  }) async {
    if (userId == null) {
      throw StateError('No logged-in user. Cannot save bills without user_id.');
    }

    final sp = await SharedPreferences.getInstance();
    final key = _keyForUser(userId);
    final raw = sp.getString(key);
    final existing = raw == null
        ? <BillModel>[]
        : (jsonDecode(raw) as List)
            .cast<Map>()
            .map((e) => BillModel.fromJson(e.cast<String, dynamic>()))
            .toList();

    existing.add(bill);
    existing.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await sp.setString(key, jsonEncode(existing.map((b) => b.toJson()).toList()));
  }
}

