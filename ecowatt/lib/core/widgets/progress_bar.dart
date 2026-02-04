import 'package:flutter/material.dart';

/// Simple step progress indicator used across setup/configuration flows.
class ProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;

  const ProgressBar({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step of $totalSteps'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}

