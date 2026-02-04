import 'package:flutter/material.dart';

import 'routes.dart';
import 'state_container.dart';
import 'theme.dart';

class EcoWattApp extends StatelessWidget {
  const EcoWattApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateScope.bootstrap(
      child: Builder(
        builder: (context) {
          final state = AppStateScope.of(context);
          return AnimatedBuilder(
            animation: state.settings,
            builder: (context, _) {
              final isDark = state.settings.isDarkMode;
              return MaterialApp(
                title: 'ECOWATT',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                initialRoute: AppRoutes.login,
                onGenerateRoute: AppRoutes.onGenerateRoute,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

