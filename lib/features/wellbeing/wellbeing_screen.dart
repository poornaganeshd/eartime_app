import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/logic/exposure_math.dart';
import '../../domain/logic/listening_analyzer.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../widgets/charts.dart';
import '../widgets/editorial_metric.dart';
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';

/// Hearing health: live level, weekly WHO dose, score and guidance.
class WellbeingScreen extends ConsumerWidget {
  final VoidCallback? onOpenSettings;

  const WellbeingScreen({super.key, this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final live = ref.watch(liveSessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final insight = ref.watch(hearingInsightProvider).value;
    final week = ref.watch(statsProvider(StatsRange.week)).value;
    final liveDb = ExposureMath.estimatedDb(prefs.maxOutputDb, live.volume?.attenuationDb);
    final playing = live.isPlaying && liveDb > 0;

    return TabPage(
      onOpenSettings: onOpenSettings,
      orbA: const Alignment(0.2, -1.2),
      orbB: const Alignment(-1.2, 0.9),
      slivers: [
        const SliverToBoxAdapter(child: ScreenTitle(eyebrow: 'Safe listening', title: 'Hearing')),

        // Live level.
        SliverToBoxAdapter(
          child: Gap(
            LiquidGlassSurface(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('LIVE LEVEL', style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary)),
                      const Spacer(),
                      Text(
                        live.volume == null ? 'Volume --' : 'Volume ${live.volume!.percent}%',
                        style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LevelGauge(db: liveDb, active: playing),
                  const SizedBox(height: 12),
                  Text(
                    playing
                        ? 'At this level it is safe to listen for about ${Fmt.duration(ExposureMath.dailyAllowance(liveDb))} a day.'
                        : 'Start playback through your headphones to see the estimated level.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Score & recommendation.
        SliverToBoxAdapter(
          child: Gap(
            LiquidGlassSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreBadge(score: insight?.score),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HEARING SCORE', style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary)),
                        const SizedBox(height: 6),
                        Text(insight?.headline ?? '…', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(insight?.recommendation ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: p.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Weekly allowance.
        const SliverToBoxAdapter(child: SectionHeader(title: 'Weekly sound allowance')),
        SliverToBoxAdapter(
          child: Gap(
            LiquidGlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AllowanceMeter(
                    fraction: week?.dose ?? 0,
                    label: 'Last 7 days',
                    caption: week == null || week.unknownLevelTime == Duration.zero
                        ? null
                        : '${Fmt.duration(week.unknownLevelTime)} recorded before volume tracking is not included.',
                  ),
                  const SizedBox(height: 20),
                  if (week != null)
                    ColumnChart(
                      height: 120,
                      values: week.bucketDose,
                      labels: [for (final d in week.bucketStarts) Fmt.weekday(d).substring(0, 1)],
                      tooltips: [
                        for (var i = 0; i < week.bucketStarts.length; i++)
                          '${Fmt.day(week.bucketStarts[i])} · ${Fmt.percent(week.bucketDose[i])} of weekly dose · ${Fmt.duration(week.buckets[i])}',
                      ],
                      highlightIndex: week.bucketStarts.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Week metrics.
        SliverToBoxAdapter(
          child: Gap(
            Row(
              children: [
                Expanded(
                  child: LiquidGlassSurface(
                    padding: const EdgeInsets.all(16),
                    child: EditorialMetric(
                      label: 'Avg level',
                      value: week?.averageDb == null ? '--' : '${week!.averageDb!.round()}',
                      unit: week?.averageDb == null ? null : 'dB',
                      caption: '7-day Leq',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LiquidGlassSurface(
                    padding: const EdgeInsets.all(16),
                    child: EditorialMetric(
                      label: 'Loud time',
                      value: Fmt.duration(week?.loudTime ?? Duration.zero),
                      caption: '≥ 80 dB',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LiquidGlassSurface(
                    padding: const EdgeInsets.all(16),
                    child: EditorialMetric(
                      label: 'Breaks',
                      value: '${week?.breaks ?? 0}',
                      caption: '≥ 5 min',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Safe listening guide.
        const SliverToBoxAdapter(child: SectionHeader(title: 'How long is safe?')),
        SliverToBoxAdapter(child: Gap(_SafeTimeTable(currentDb: playing ? liveDb : null))),

        SliverToBoxAdapter(
          child: Gap(
            LiquidGlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ABOUT THESE NUMBERS', style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    'Levels are estimated from your media volume and the maximum output of your headphones '
                    '(${prefs.maxOutputDb.round()} dB, adjustable in Settings). The weekly allowance follows '
                    'the WHO/ITU-T H.870 safe-listening standard: 80 dB for 40 hours a week, halved for every 3 dB louder.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int? score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = score;
    final color = value == null
        ? p.textTertiary
        : value >= 80
            ? p.success
            : value >= 50
                ? p.warning
                : p.danger;
    return ProgressRing(
      progress: (value ?? 0) / 100,
      size: 84,
      stroke: 8,
      color: color,
      semanticsLabel: value == null ? 'No hearing score yet' : 'Hearing score $value out of 100',
      child: FittedBox(
        child: Text(
          value?.toString() ?? '--',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFeatures: tabularFigures),
        ),
      ),
    );
  }
}

class _SafeTimeTable extends StatelessWidget {
  final double? currentDb;

  const _SafeTimeTable({required this.currentDb});

  static const _levels = [75.0, 80.0, 85.0, 90.0, 95.0, 100.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final current = currentDb;
    int? nearest;
    if (current != null) {
      var best = double.infinity;
      for (var i = 0; i < _levels.length; i++) {
        final d = (_levels[i] - current).abs();
        if (d < best) {
          best = d;
          nearest = i;
        }
      }
    }
    return LiquidGlassSurface(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < _levels.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: nearest == i ? p.accent.withValues(alpha: 0.12) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: p.forLevel(_levels[i]))),
                  const SizedBox(width: 10),
                  SizedBox(width: 64, child: Text('${_levels[i].round()} dB', style: theme.textTheme.labelLarge)),
                  Expanded(
                    child: Text(
                      EarPalette.levelLabel(_levels[i]),
                      style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ),
                  Text(
                    '${Fmt.duration(ExposureMath.dailyAllowance(_levels[i]))} / day',
                    style: theme.textTheme.labelLarge?.copyWith(color: p.textPrimary),
                  ),
                  if (nearest == i) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_left_rounded, color: p.accent, semanticLabel: 'your current level'),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
