import 'package:flutter/foundation.dart';

import '../data/repositories/appliance_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/settings_repository.dart';

import 'appliance_state.dart';
import 'auth_state.dart';
import 'bill_state.dart';
import 'settings_state.dart';
import '../auth/auth_service.dart';

/// Root state container. UI reads state only; controllers mutate it.
class AppState extends ChangeNotifier {
  late final SettingsState settings;
  late final AuthState auth;
  late final BillState bills;
  late final ApplianceState appliances;

  AppState({
    required SettingsRepository settingsRepository,
    required AuthService authService,
    required BillRepository billRepository,
    required ApplianceRepository applianceRepository,
  }) {
    settings = SettingsState(settingsRepository);
    auth = AuthState(authService);
    bills = BillState(billRepository);
    appliances = ApplianceState(applianceRepository);

    // Bubble up child notifications so shell screens can rebuild.
    settings.addListener(notifyListeners);
    auth.addListener(notifyListeners);
    bills.addListener(notifyListeners);
    appliances.addListener(notifyListeners);
  }

  Future<void> init() async {
    // Order matters: bills must load after we know the current user.
    await settings.load();
    await auth.load();
    await Future.wait([
      bills.load(userId: auth.currentUserId),
      appliances.load(),
    ]);
  }

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    auth.removeListener(notifyListeners);
    bills.removeListener(notifyListeners);
    appliances.removeListener(notifyListeners);
    settings.dispose();
    auth.dispose();
    bills.dispose();
    appliances.dispose();
    super.dispose();
  }
}

