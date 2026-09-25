import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Circular progress ring (e.g. today's listening vs the daily goal). Values above 1.0 wrap a
/// second lap in the warning colour so "over goal" is visible, and the centre shows [child].
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Widget child;
  final Color? color;
  final String semanticsLabel;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    required this.semanticsLabel,
    this.size = 240,
    this.stroke = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.isFinite ? math.max(0, progress) : 0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _RingPainter(
              progress: value,
              stroke: stroke,
              track: p.surfaceHigh,
              start: (color ?? p.accent).withValues(alpha: 0.65),
              end: color ?? p.accent,
              over: p.warning,
            ),
            child: Center(child: Padding(padding: EdgeInsets.all(stroke + 8), child: child)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color track;
  final Color start;
  final Color end;
  final Color over;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.start,
    required this.end,
    required this.over,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);

    final first = progress.clamp(0.0, 1.0);
    if (first > 0) {
      final sweep = math.pi * 2 * first;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [start, end],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect);
      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, paint);
    }
    final extra = (progress - 1).clamp(0.0, 1.0);
    if (extra > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.55
        ..strokeCap = StrokeCap.round
        ..color = over;
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * extra, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.end != end || old.over != over;
}

/// Semicircular sound-level gauge with the WHO-aligned zones (safe < 80 dB ≤ loud < 90 dB ≤ very loud).
class LevelGauge extends StatelessWidget {
  final double db;
  final bool active;
  final double minDb;
  final double maxDb;

  const LevelGauge({super.key, required this.db, required this.active, this.minDb = 40, this.maxDb = 110});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final label = active ? EarPalette.levelLabel(db) : 'Idle';
    return Semantics(
      label: active ? 'Estimated level ${db.round()} decibels, $label' : 'No audio playing',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 2,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: minDb, end: active ? db.clamp(minDb, maxDb) : minDb),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _GaugePainter(
              value: value,
              minDb: minDb,
              maxDb: maxDb,
              track: p.surfaceHigh,
              zones: [(80, p.success), (90, p.warning), (maxDb, p.danger)],
              needle: p.textPrimary,
              active: active,
            ),
            child: Align(
              alignment: const Alignment(0, 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        active ? '${db.round()}' : '--',
                        style: theme.textTheme.displayMedium?.copyWith(fontFeatures: tabularFigures),
                      ),
                      const SizedBox(width: 4),
                      Text('dB', style: theme.textTheme.labelLarge?.copyWith(color: p.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: active ? p.forLevel(db) : p.textTertiary),
                      ),
                      const SizedBox(width: 6),
                      Text(label.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minDb;
  final double maxDb;
  final Color track;
  final List<(double, Color)> zones;
  final Color needle;
  final bool active;

  _GaugePainter({
    required this.value,
    required this.minDb,
    required this.maxDb,
    required this.track,
    required this.zones,
    required this.needle,
    required this.active,
  });

  double _angle(double db) => math.pi + math.pi * ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final radius = math.min(size.width / 2, size.height) - stroke;
    final center = Offset(size.width / 2, size.height - 4);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Zone arcs, separated by 2px surface gaps (drawn as small angular gaps).
    var from = minDb;
    const gap = 0.02;
    for (final (to, color) in zones) {
      final a0 = _angle(from) + (from == minDb ? 0 : gap / 2);
      final a1 = _angle(to) - (to == maxDb ? 0 : gap / 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = active ? color.withValues(alpha: 0.9) : track;
      canvas.drawArc(rect, a0, a1 - a0, false, paint);
      from = to;
    }

    // Needle tick.
    final a = _angle(value);
    final inner = center + Offset(math.cos(a), math.sin(a)) * (radius - stroke - 6);
    final outer = center + Offset(math.cos(a), math.sin(a)) * (radius + stroke / 2 + 2);
    canvas.drawLine(
      inner,
      outer,
      Paint()
        ..color = active ? needle : needle.withValues(alpha: 0.3)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.active != active || old.track != track;
}

/// Single-series column chart with a tap-to-inspect tooltip, a recessive baseline, and only the
/// maximum value labelled directly. Screen readers get every bucket via semantics.
class ColumnChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;

  /// Labels shown under the axis (subset of [labels] to avoid crowding); null = auto.
  final bool Function(int index)? showLabel;
  final List<String> tooltips;
  final int? highlightIndex;
  final double height;

  const ColumnChart({
    super.key,
    required this.values,
    required this.labels,
    required this.tooltips,
    this.showLabel,
    this.highlightIndex,
    this.height = 160,
  });

  @override
  State<ColumnChart> createState() => _ColumnChartState();
}

class _ColumnChartState extends State<ColumnChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final n = widget.values.length;
    final maxValue = widget.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxIndex = maxValue <= 0 ? null : widget.values.indexOf(maxValue);
    final selected = _selected;

    return Semantics(
      label: 'Listening chart. ${[
        for (var i = 0; i < n; i++)
          if (widget.values[i] > 0) widget.tooltips[i]
      ].join('. ')}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 22,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected == null
                  ? Align(
                      key: const ValueKey('hint'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        maxIndex == null ? 'No listening in this period' : 'Peak ${widget.tooltips[maxIndex]}',
                        style: theme.textTheme.bodySmall?.copyWith(color: p.textTertiary),
                      ),
                    )
                  : Align(
                      key: ValueKey(selected),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.tooltips[selected],
                        style: theme.textTheme.titleSmall?.copyWith(color: p.textPrimary),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / math.max(1, n);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => setState(() {
                    final i = (d.localPosition.dx / slot).floor().clamp(0, n - 1);
                    _selected = _selected == i ? null : i;
                  }),
                  onHorizontalDragUpdate: (d) => setState(() {
                    _selected = (d.localPosition.dx / slot).floor().clamp(0, n - 1);
                  }),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _ColumnPainter(
                        values: widget.values,
                        max: maxValue,
                        t: t,
                        color: p.accent,
                        muted: p.accent.withValues(alpha: 0.5),
                        grid: p.border,
                        selected: selected,
                        highlight: widget.highlightIndex,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Text(
                    (widget.showLabel?.call(i) ?? true) ? widget.labels[i] : '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == selected ? p.textPrimary : p.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnPainter extends CustomPainter {
  final List<double> values;
  final double max;
  final double t;
  final Color color;
  final Color muted;
  final Color grid;
  final int? selected;
  final int? highlight;

  _ColumnPainter({
    required this.values,
    required this.max,
    required this.t,
    required this.color,
    required this.muted,
    required this.grid,
    required this.selected,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    // Recessive hairline baseline.
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );
    if (max <= 0) return;

    final slot = size.width / n;
    final barWidth = math.min(24.0, slot - 2); // ≤ 24px thick, ≥ 2px surface gap.
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final h = math.max(3.0, (size.height - 2) * (v / max) * t);
      final left = slot * i + (slot - barWidth) / 2;
      final rect = Rect.fromLTWH(left, size.height - 1 - h, barWidth, h);
      final emphasised = selected == null ? (highlight == null || highlight == i) : selected == i;
      final radius = Radius.circular(math.min(4, barWidth / 2));
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
        Paint()..color = emphasised ? color : muted,
      );
    }
  }

  @override
  bool shouldRepaint(_ColumnPainter old) =>
      old.t != t || old.values != values || old.selected != selected || old.color != color || old.max != max;
}

/// Horizontal meter for a fraction of an allowance (e.g. weekly sound dose), with status label.
class AllowanceMeter extends StatelessWidget {
  final double fraction;
  final String label;
  final String? caption;

  const AllowanceMeter({super.key, required this.fraction, required this.label, this.caption});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final color = fraction >= 1
        ? p.danger
        : fraction >= 0.8
            ? p.warning
            : p.success;
    final status = fraction >= 1
        ? 'Over limit'
        : fraction >= 0.8
            ? 'Near limit'
            : 'On track';
    return Semantics(
      label: '$label ${Fmt.percent(fraction)}, $status',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 6),
              Text('${Fmt.percent(fraction)} · $status', style: theme.textTheme.labelLarge?.copyWith(color: p.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: p.surfaceHigh)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
          ],
        ],
      ),
    );
  }
}
