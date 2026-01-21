import '../../app/state_container.dart';
import '../../data/models/tariff_model.dart';

class SettingsController {
  Future<void> saveTariff(AppStateScope scope, TariffModel tariff) async {
    await scope.notifier!.settings.saveTariff(tariff);
  }
}


