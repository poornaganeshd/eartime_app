import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft colour orbs behind every screen. Drawn with radial gradients (cheap) instead of huge
/// blurred box-shadows (expensive), and isolated in a RepaintBoundary.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  final Alignment primaryAlignment;
  final Alignment secondaryAlignment;

  const AmbientBackground({
    super.key,
    required this.child,
    this.primaryAlignment = const Alignment(-1.1, -1.0),
    this.secondaryAlignment = const Alignment(1.2, 0.6),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    _Orb(alignment: primaryAlignment, color: p.orbA, size: 420),
                    _Orb(alignment: secondaryAlignment, color: p.orbB, size: 360),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Orb({required this.alignment, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
