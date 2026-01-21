import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_model.dart';

class BillRepository {
  static const _billsKey = 'ecowatt_bills';

  Future<List<BillModel>> getBills() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_billsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map>();
    return list
        .map((e) => BillModel.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveBills(List<BillModel> bills) async {
    final sp = await SharedPreferences.getInstance();
    final jsonList = bills.map((b) => b.toJson()).toList();
    await sp.setString(_billsKey, jsonEncode(jsonList));
  }

  Future<void> upsertBill(BillModel bill) async {
    final bills = await getBills();
    final idx = bills.indexWhere((b) => b.billId == bill.billId);
    if (idx >= 0) {
      bills[idx] = bill;
    } else {
      bills.add(bill);
    }
    bills.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await saveBills(bills);
  }
}

