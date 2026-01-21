import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/appliance_model.dart';

class ApplianceRepository {
  static const _appliancesKey = 'ecowatt_appliances';

  Future<List<ApplianceModel>> getAppliances() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_appliancesKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map>();
    return list
        .map((e) => ApplianceModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveAppliances(List<ApplianceModel> appliances) async {
    final sp = await SharedPreferences.getInstance();
    final jsonList = appliances.map((a) => a.toJson()).toList();
    await sp.setString(_appliancesKey, jsonEncode(jsonList));
  }

  Future<void> upsertAppliance(ApplianceModel appliance) async {
    final list = await getAppliances();
    final idx = list.indexWhere((a) => a.applianceId == appliance.applianceId);
    if (idx >= 0) {
      list[idx] = appliance;
    } else {
      list.add(appliance);
    }
    await saveAppliances(list);
  }

  Future<void> removeAppliance(String applianceId) async {
    final list = await getAppliances();
    list.removeWhere((a) => a.applianceId == applianceId);
    await saveAppliances(list);
  }
}

