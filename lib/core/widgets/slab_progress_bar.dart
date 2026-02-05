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
    // Progress bar: slab table ranges only — progressMin=start, progressMax=end, progressValue=units
    final start = progress.currentSlabStart;
    final end = progress.currentSlabLimit;
    final units = progress.currentUnits;

    // Progress within current slab: (units - start) / (end - start)
    final slabSpan = end - start;
    final ratio = slabSpan > 0
        ? ((units - start) / slabSpan).clamp(0.0, 1.0)
        : 0.0;

    final remaining = progress.unitsToNextSlab;
    // Only show "Highest slab" when units >= 801 (never for 401, 498, etc.)
    final isHighestSlab = start >= 801;

    final color = _colorForRemaining(
      remaining: remaining,
      hasNext: progress.nextSlabLimit != null,
      theme: theme,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${units.toStringAsFixed(0)} / ${end.toStringAsFixed(0)} units',
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
            if (remaining != null)
              Text(
                '${remaining.toStringAsFixed(0)} units left',
                style: theme.textTheme.bodySmall,
              )
            else if (isHighestSlab)
              Text(
                'Highest slab',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        if (remaining != null && remaining <= 20)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.s8),
            child: Text(
              '⚠ You are ${remaining.toStringAsFixed(0)} units away from the next slab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _warningColor(remaining),
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

