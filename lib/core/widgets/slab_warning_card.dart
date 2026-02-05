import 'package:flutter/material.dart';

import '../../logic/billing/billing_result.dart';

/// Slab warning state derived from SlabProgress.
/// Uses: slabSize = end - start + 1, usedInSlab = units - start + 1,
/// percentUsed = usedInSlab / slabSize, unitsLeft = end - units.
enum SlabWarningLevel { none, nearLimit, crossed }

/// Computes slab warning level from SlabProgress.
SlabWarningLevel computeSlabWarningLevel(SlabProgress progress) {
  final units = progress.currentUnits;
  final start = progress.currentSlabStart;
  final end = progress.currentSlabLimit;
  final isHighestSlab = progress.nextSlabLimit == null;

  final slabSize = end - start + 1;
  final usedInSlab = units - start + 1;
  final percentUsed = slabSize > 0 ? usedInSlab / slabSize : 0.0;

  // RED: percentUsed >= 1.0 OR user is inside highest slab
  if (percentUsed >= 1.0 || isHighestSlab) {
    return SlabWarningLevel.crossed;
  }
  // YELLOW: percentUsed >= 0.80 AND percentUsed < 1.0
  if (percentUsed >= 0.80) {
    return SlabWarningLevel.nearLimit;
  }
  return SlabWarningLevel.none;
}

/// Inline warning card for slab proximity. Updates live with billing preview.
class SlabWarningCard extends StatelessWidget {
  final SlabProgress progress;

  const SlabWarningCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final level = computeSlabWarningLevel(progress);
    if (level == SlabWarningLevel.none) return const SizedBox.shrink();

    final units = progress.currentUnits;
    final end = progress.currentSlabLimit;
    final unitsLeft = (end - units).round().clamp(0, 9999);

    final isRed = level == SlabWarningLevel.crossed;

    final bgColor = isRed
        ? const Color(0xFFFFEBEE) // Light red
        : const Color(0xFFFFFDE7); // Light yellow
    final borderColor = isRed ? const Color(0xFFD32F2F) : const Color(0xFFF9A825);
    final textColor = isRed ? const Color(0xFFB71C1C) : const Color(0xFF6D4C00);
    final icon = isRed ? Icons.error_outline : Icons.warning_amber_rounded;

    final title = isRed ? '🚨 Slab Warning' : '⚠️ Slab Warning';
    final message = isRed
        ? 'You are now in a higher tariff slab.\nEach additional unit costs more.'
        : 'You are close to the next slab.\nOnly $unitsLeft units left before higher tariff applies.';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: borderColor, width: 5),
          top: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
