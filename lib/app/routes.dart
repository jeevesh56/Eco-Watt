import 'package:flutter/material.dart';

import '../features/analysis/analysis_screen.dart';
import '../features/appliance_detail/appliance_detail_screen.dart';
import '../features/configuration/appliance_config_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/month_review/month_review_screen.dart';
import '../features/savings/savings_screen.dart';
import '../features/shell/bottom_nav_shell.dart';
import '../features/setup/setup_screen.dart';
import '../features/auth/login_register_page.dart';

/// Centralized named routes for the whole app.
class AppRoutes {
  static const root = '/';

  static const setup = '/setup';
  static const configuration = '/configuration';
  static const analysis = '/analysis';
  static const applianceDetail = '/appliance-detail';
  static const history = '/history';
  static const settings = '/settings';
  static const monthReview = '/month-review';
  static const savings = '/savings';
  static const login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    switch (routeName) {
      case root:
        return MaterialPageRoute(builder: (_) => const BottomNavShell());
      case setup:
        return MaterialPageRoute(builder: (_) => const SetupScreen());
      case configuration:
        return MaterialPageRoute(builder: (_) => const ApplianceConfigScreen());
      case analysis:
        // Keep analysis accessible via the bottom navigation shell so that
        // the dashboard is always visible. Route here just returns the shell.
        return MaterialPageRoute(builder: (_) => const BottomNavShell());
      case applianceDetail:
        return MaterialPageRoute(
          builder: (_) => ApplianceDetailScreen(
            applianceId: (settings.arguments as String?) ?? '',
          ),
        );
      case history:
        return MaterialPageRoute(builder: (_) => const BottomNavShell());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const BottomNavShell());
      case AppRoutes.monthReview:
        return MaterialPageRoute(builder: (_) => const MonthReviewScreen());
      case AppRoutes.savings:
        return MaterialPageRoute(builder: (_) => const SavingsScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginRegisterPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}

