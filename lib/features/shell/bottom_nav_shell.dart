import 'package:flutter/material.dart';

import '../../core/constants/strings.dart';
import '../analysis/analysis_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../setup/setup_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 0;

  final _pages = const [
    SetupScreen(),
    AnalysisScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: AppStrings.setupTitle),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: AppStrings.analysisTitle),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Profile'),
        ],
      ),
    );
  }
}

