import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tariff_model.dart';
import '../models/user_model.dart';

class SettingsRepository {
  static const _userKey = 'ecowatt_user';
  static const _tariffKey = 'ecowatt_tariff';

  Future<UserModel?> getUser() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<TariffModel?> getTariff() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_tariffKey);
    if (raw == null) return null;
    return TariffModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveTariff(TariffModel tariff) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tariffKey, jsonEncode(tariff.toJson()));
  }
}

