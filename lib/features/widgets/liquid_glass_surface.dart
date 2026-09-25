import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The app's card surface: a soft translucent panel with a hairline border and top highlight.
///
/// Background blur is opt-in ([blur]): a BackdropFilter per card inside scrolling lists is one of
/// the most expensive things Flutter can render and caused visible jank on the timeline.
class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool blur;
  final Color? tint;
  final String? semanticLabel;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.onTap,
    this.blur = false,
    this.tint,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final base = tint == null
        ? (isDark ? p.surface.withValues(alpha: 0.72) : p.surface)
        : Color.alphaBlend(tint!.withValues(alpha: isDark ? 0.10 : 0.07), isDark ? p.surface : p.surface);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: base,
        border: Border.all(color: p.border),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.035), Colors.white.withValues(alpha: 0.0)],
              )
            : null,
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (blur) {
      content = BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: content);
    }

    content = ClipRRect(borderRadius: radius, child: content);
    if (semanticLabel != null) {
      content = Semantics(label: semanticLabel, button: onTap != null, child: content);
    }
    return content;
  }
}
