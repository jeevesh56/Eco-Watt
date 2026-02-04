import '../../state/app_state.dart';
import '../../data/models/tariff_model.dart';

class SettingsController {
  Future<void> saveTariff(AppState scope, TariffModel tariff) async {
    await scope.settings.saveTariff(tariff);
  }
}


