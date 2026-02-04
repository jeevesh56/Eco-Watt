import 'package:flutter/foundation.dart';

import '../data/models/appliance_model.dart';
import '../data/repositories/appliance_repository.dart';

class ApplianceState extends ChangeNotifier {
  final ApplianceRepository _repo;

  ApplianceState(this._repo);

  bool _loaded = false;
  bool get loaded => _loaded;

  final List<ApplianceModel> _items = [];
  List<ApplianceModel> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _items
      ..clear()
      ..addAll(await _repo.getAppliances());
    _loaded = true;
    notifyListeners();
  }

  ApplianceModel? byId(String id) {
    for (final a in _items) {
      if (a.applianceId == id) return a;
    }
    return null;
  }

  Future<void> upsert(ApplianceModel appliance) async {
    await _repo.upsertAppliance(appliance);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.removeAppliance(id);
    await load();
  }
}

