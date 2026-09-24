import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A labelled number, e.g. "AVG LEVEL · 72 dB".
class EditorialMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;
  final bool glow;
  final CrossAxisAlignment alignment;
  final IconData? icon;
  final String? caption;

  const EditorialMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.glow = false,
    this.alignment = CrossAxisAlignment.start,
    this.icon,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final valColor = valueColor ?? p.textPrimary;

    return Semantics(
      label: '$label: $value${unit == null ? '' : ' $unit'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: p.textSecondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment == CrossAxisAlignment.center ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: valColor,
                    fontFeatures: tabularFigures,
                    shadows: glow ? [Shadow(color: valColor.withValues(alpha: 0.35), blurRadius: 18)] : null,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(unit!, style: theme.textTheme.labelLarge?.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: p.textTertiary)),
          ],
        ],
      ),
    );
  }
}
