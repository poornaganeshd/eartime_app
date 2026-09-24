import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Labelled horizontal proportion bar.
class DataVisualizationBar extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final String label;
  final String? valueText;
  final String? caption;
  final Color? color;
  final bool animate;

  const DataVisualizationBar({
    super.key,
    required this.percentage,
    required this.label,
    this.valueText,
    this.caption,
    this.color,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final barColor = color ?? p.accent;
    final value = percentage.isNaN ? 0.0 : percentage.clamp(0.0, 1.0);

    return Semantics(
      label: '$label ${valueText ?? ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: label, style: theme.textTheme.titleSmall?.copyWith(color: p.textPrimary)),
                    if (caption != null)
                      TextSpan(text: '  $caption', style: theme.textTheme.bodySmall?.copyWith(color: p.textTertiary)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (valueText != null) ...[
                const SizedBox(width: 12),
                Text(valueText!, style: theme.textTheme.labelLarge?.copyWith(color: p.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: p.surfaceHigh)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: animate ? const Duration(milliseconds: 700) : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [barColor.withValues(alpha: 0.7), barColor]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
