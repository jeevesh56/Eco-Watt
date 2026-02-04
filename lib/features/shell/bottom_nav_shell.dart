import 'package:flutter/material.dart';

import '../../core/constants/strings.dart';
import '../analysis/analysis_screen.dart';
import '../history/history_screen.dart';
import '../setup/setup_screen.dart';

class BottomNavShell extends StatefulWidget {
  /// Initial tab index (0=Setup, 1=Analysis, 2=Bills). No Profile tab.
  final int initialIndex;

  const BottomNavShell({super.key, this.initialIndex = 0});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  late int _index;

  final _pages = const [
    SetupScreen(),
    AnalysisScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

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
        ],
      ),
    );
  }
}

