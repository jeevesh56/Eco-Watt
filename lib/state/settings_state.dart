import 'package:flutter/foundation.dart';

import '../data/models/tariff_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/settings_repository.dart';

class SettingsState extends ChangeNotifier {
  final SettingsRepository _repo;

  SettingsState(this._repo);

  bool _loaded = false;
  bool get loaded => _loaded;

  UserModel? _user;
  UserModel? get user => _user;

  TariffModel _tariff = const TariffModel(
    providerName: 'TNDPCL Corporation Limited',
    baseRate: 6.50,
    tieredPricing: [
      TariffTierModel(upToKWh: 100, rate: 0.0),
      TariffTierModel(upToKWh: 200, rate: 2.35),
      TariffTierModel(upToKWh: 400, rate: 4.70),
      TariffTierModel(upToKWh: 500, rate: 6.30),
    ],
    currency: '₹',
  );
  TariffModel get tariff => _tariff;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> load() async {
    _user = await _repo.getUser();
    _tariff = await _repo.getTariff() ?? _tariff;
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    _user = user;
    await _repo.saveUser(user);
    notifyListeners();
  }

  Future<void> saveTariff(TariffModel tariff) async {
    _tariff = tariff;
    await _repo.saveTariff(tariff);
    notifyListeners();
  }
}

