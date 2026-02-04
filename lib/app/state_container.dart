import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/repositories/appliance_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../state/app_state.dart';

/// Lightweight DI + state holder without third-party state libs.
/// UI reads state through [AppStateScope.of(context)] only.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }

  static Widget bootstrap({required Widget child}) {
    final authService = AuthService.instance;
    final state = AppState(
      settingsRepository: SettingsRepository(),
      authService: authService,
      billRepository: BillRepository(),
      applianceRepository: ApplianceRepository(),
    );

    return _Bootstrapper(state: state, child: child);
  }
}

class _Bootstrapper extends StatefulWidget {
  final AppState state;
  final Widget child;

  const _Bootstrapper({required this.state, required this.child});

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  late Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = widget.state.init();
  }

  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        return AppStateScope(
          notifier: widget.state,
          child: widget.child,
        );
      },
    );
  }
}

