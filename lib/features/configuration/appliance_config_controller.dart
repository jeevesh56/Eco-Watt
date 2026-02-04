import '../../app/state_container.dart';
import '../../data/models/appliance_model.dart';
import '../../data/mock/appliances_catalog.dart';

class ApplianceConfigController {
  /// Catalog is static (from /data/mock). We only persist user-selected appliances.
  Future<void> ensureCatalogSeeded(AppStateScope scope) async {
    // Intentionally no-op: do not auto-select appliances.
  }

  Future<void> setSelected(
    AppStateScope scope,
    ApplianceModel appliance,
    bool selected,
  ) async {
    final state = scope.notifier!;
    if (selected) {
      await state.appliances.upsert(appliance);
    } else {
      await state.appliances.remove(appliance.applianceId);
    }
  }

  Future<void> updateUsageLevel(
    AppStateScope scope,
    ApplianceModel appliance,
    String usageLevel,
  ) async {
    final state = scope.notifier!;
    await state.appliances.upsert(
      appliance.copyWith(
        usageLevel: usageLevel,
        dailyHours: AppliancesCatalog.usageHours(usageLevel),
      ),
    );
  }

  Future<void> updateStarRating(
    AppStateScope scope,
    ApplianceModel appliance,
    int stars,
  ) async {
    final state = scope.notifier!;
    await state.appliances.upsert(appliance.copyWith(starRating: stars.clamp(1, 5)));
  }

  Future<void> updateCount(
    AppStateScope scope,
    ApplianceModel appliance,
    int count,
  ) async {
    final state = scope.notifier!;
    final safe = count.clamp(1, 20);
    await state.appliances.upsert(appliance.copyWith(count: safe));
  }
}


