import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../logic/billing/billing_result.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

/// Read-only visual showing how close the user is to the next slab.
class SlabProgressBar extends StatelessWidget {
  final SlabProgress progress;

  const SlabProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Progress bar uses values from billing calculation
    final start = progress.currentSlabStart;
    final end = progress.currentSlabLimit;
    final units = progress.currentUnits;
    
    // Progress calculation: units / end (as per user requirements)
    // This shows progress from 0 to end within the current slab
    final ratio = (end > 0) ? (units / end).clamp(0.0, 1.0) : 0.0;
    
    // Use unitsLeftInSlab from billing calculation
    final unitsLeft = progress.unitsLeftInSlab;

    final color = _colorForRemaining(
      remaining: unitsLeft > 0 ? unitsLeft : null,
      hasNext: progress.nextSlabLimit != null,
      theme: theme,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${units.toStringAsFixed(1)} / ${end.toStringAsFixed(0)} units',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Slab ${start.toStringAsFixed(0)}–${end.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Row(
          children: [
            Text(
              'From ${start.toStringAsFixed(0)} to ${end.toStringAsFixed(0)} units',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            if (progress.nextSlabLimit != null)
              Text(
                '${unitsLeft.toStringAsFixed(0)} units left',
                style: theme.textTheme.bodySmall,
              )
            else
              Text(
                'Highest slab',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        if (progress.nextSlabLimit != null && unitsLeft <= 20 && unitsLeft > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.s8),
            child: Text(
              '⚠ You are ${unitsLeft.toStringAsFixed(0)} units away from the next slab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _warningColor(unitsLeft),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Color _colorForRemaining({
    required double? remaining,
    required bool hasNext,
    required ThemeData theme,
  }) {
    if (!hasNext) return theme.colorScheme.primary;
    if (remaining == null) return AppColors.greenPrimary;
    if (remaining <= 10) return AppColors.danger;
    if (remaining <= 20) return AppColors.warning;
    return AppColors.greenPrimary;
  }

  Color _warningColor(double remaining) {
    if (remaining <= 10) return AppColors.danger;
    return AppColors.warning;
  }
}

