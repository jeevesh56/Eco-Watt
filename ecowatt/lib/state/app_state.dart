import 'package:flutter/foundation.dart';

import '../data/repositories/appliance_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/settings_repository.dart';

import 'appliance_state.dart';
import 'bill_state.dart';
import 'settings_state.dart';

/// Root state container. UI reads state only; controllers mutate it.
class AppState extends ChangeNotifier {
  late final SettingsState settings;
  late final BillState bills;
  late final ApplianceState appliances;

  AppState({
    required SettingsRepository settingsRepository,
    required BillRepository billRepository,
    required ApplianceRepository applianceRepository,
  }) {
    settings = SettingsState(settingsRepository);
    bills = BillState(billRepository);
    appliances = ApplianceState(applianceRepository);

    // Bubble up child notifications so shell screens can rebuild.
    settings.addListener(notifyListeners);
    bills.addListener(notifyListeners);
    appliances.addListener(notifyListeners);
  }

  Future<void> init() async {
    await Future.wait([
      settings.load(),
      bills.load(),
      appliances.load(),
    ]);
  }

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    bills.removeListener(notifyListeners);
    appliances.removeListener(notifyListeners);
    settings.dispose();
    bills.dispose();
    appliances.dispose();
    super.dispose();
  }
}

