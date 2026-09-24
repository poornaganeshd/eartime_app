import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pill with a status dot; the dot pulses while [pulse] is true (e.g. live listening).
class StatusIndicator extends StatefulWidget {
  final bool isActive;
  final String label;
  final Color? color;
  final bool pulse;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.label,
    this.color,
    this.pulse = false,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldPulse = widget.pulse && widget.isActive && !(WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations);
    if (shouldPulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.color ?? (widget.isActive ? p.success : p.textTertiary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (t > 0)
                      Container(
                        width: 6 + 10 * t,
                        height: 6 + 10 * t,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.4 * (1 - t))),
                      ),
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
