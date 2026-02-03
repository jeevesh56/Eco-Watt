import 'package:flutter/material.dart';

import 'routes.dart';
import 'state_container.dart';
import 'theme.dart';

class EcoWattApp extends StatelessWidget {
  const EcoWattApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateScope.bootstrap(
      child: MaterialApp(
        title: 'ECOWATT',
        theme: AppTheme.light,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

