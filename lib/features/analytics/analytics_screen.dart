import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/logic/listening_analyzer.dart';
import '../../providers/data_providers.dart';
import '../home/home_screen.dart' show deviceIcon;
import '../widgets/charts.dart';
import '../widgets/data_visualization_bar.dart';
import '../widgets/editorial_metric.dart';
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenSettings;

  const AnalyticsScreen({super.key, this.onOpenSettings});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider(_range));

    return TabPage(
      onOpenSettings: widget.onOpenSettings,
      orbA: const Alignment(1.2, -1.0),
      orbB: const Alignment(-1.2, 0.4),
      slivers: [
        const SliverToBoxAdapter(child: ScreenTitle(eyebrow: 'Your listening', title: 'Insights')),
        SliverToBoxAdapter(
          child: Gap(
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<StatsRange>(
                showSelectedIcon: false,
                segments: [for (final r in StatsRange.values) ButtonSegment(value: r, label: Text(r.label))],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
            ),
          ),
        ),
        statsAsync.when(
          data: (stats) => SliverList.list(children: _content(context, stats)),
          loading: () => const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Text('Could not load insights: $e')),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, ListeningStats stats) {
    final theme = Theme.of(context);
    final p = context.palette;
    final days = stats.to.difference(stats.from).inHours / 24;
    final dailyAverage = _range == StatsRange.today || days <= 0
        ? stats.total
        : Duration(seconds: (stats.total.inSeconds / days.clamp(1, 366)).round());

    String bucketLabel(int i) {
      final start = stats.bucketStarts[i];
      return switch (_range) {
        StatsRange.today => '${start.hour}',
        StatsRange.week => Fmt.weekday(start).substring(0, 1),
        StatsRange.month => '${start.day}',
        StatsRange.year => Fmt.month(start).substring(0, 1),
      };
    }

    String bucketTooltip(int i) {
      final start = stats.bucketStarts[i];
      final when = switch (_range) {
        StatsRange.today => '${Fmt.two(start.hour)}:00–${Fmt.two((start.hour + 1) % 24)}:00',
        StatsRange.week || StatsRange.month => Fmt.day(start),
        StatsRange.year => '${Fmt.month(start)} ${start.year}',
      };
      return '$when · ${Fmt.duration(stats.buckets[i])}';
    }

    final nowIndex = stats.bucketStarts.lastIndexWhere((b) => !b.isAfter(stats.to));

    return [
      Gap(
        LiquidGlassSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: EditorialMetric(
                      label: _range == StatsRange.today ? 'Listened today' : 'Total listening',
                      value: Fmt.duration(stats.total),
                    ),
                  ),
                  if (_range != StatsRange.today)
                    EditorialMetric(
                      label: 'Daily average',
                      value: Fmt.duration(dailyAverage),
                      alignment: CrossAxisAlignment.end,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ColumnChart(
                values: [for (final b in stats.buckets) b.inSeconds.toDouble()],
                labels: [for (var i = 0; i < stats.buckets.length; i++) bucketLabel(i)],
                tooltips: [for (var i = 0; i < stats.buckets.length; i++) bucketTooltip(i)],
                highlightIndex: nowIndex < 0 ? null : nowIndex,
                showLabel: switch (_range) {
                  StatsRange.today => (i) => i % 6 == 0,
                  StatsRange.month => (i) => i % 5 == 0,
                  _ => null,
                },
              ),
            ],
          ),
        ),
      ),
      Gap(
        Row(
          children: [
            Expanded(
              child: LiquidGlassSurface(
                padding: const EdgeInsets.all(16),
                child: EditorialMetric(label: 'Sessions', value: '${stats.sessionCount}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LiquidGlassSurface(
                padding: const EdgeInsets.all(16),
                child: EditorialMetric(label: 'Average', value: Fmt.duration(stats.averageSession)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LiquidGlassSurface(
                padding: const EdgeInsets.all(16),
                child: EditorialMetric(label: 'Longest', value: Fmt.duration(stats.longestContinuous)),
              ),
            ),
          ],
        ),
      ),
      const SectionHeader(title: 'Time of day'),
      Gap(
        LiquidGlassSurface(
          child: Column(
            children: [
              for (final slot in DaySlot.values) ...[
                DataVisualizationBar(
                  percentage: stats.total.inSeconds == 0 ? 0 : stats.timeOfDay[slot]!.inSeconds / stats.total.inSeconds,
                  label: slot.label,
                  caption: slot.hours,
                  valueText: Fmt.duration(stats.timeOfDay[slot]!),
                ),
                if (slot != DaySlot.values.last) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      const SectionHeader(title: 'Sound exposure'),
      Gap(
        LiquidGlassSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: EditorialMetric(
                      label: 'Avg level',
                      value: stats.averageDb == null ? '--' : '${stats.averageDb!.round()}',
                      unit: stats.averageDb == null ? null : 'dB',
                    ),
                  ),
                  Expanded(
                    child: EditorialMetric(
                      label: 'Peak',
                      value: stats.peakDb == null ? '--' : '${stats.peakDb!.round()}',
                      unit: stats.peakDb == null ? null : 'dB',
                    ),
                  ),
                  Expanded(child: EditorialMetric(label: 'Above 80 dB', value: Fmt.duration(stats.loudTime))),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Dose used in this period: ${Fmt.percent(stats.dose)} of one week\'s WHO allowance.'
                '${stats.unknownLevelTime > Duration.zero ? ' ${Fmt.duration(stats.unknownLevelTime)} was recorded before volume tracking and is excluded.' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
      ),
      const SectionHeader(title: 'Devices'),
      if (stats.devices.isEmpty)
        const EmptyState(icon: Icons.headphones_rounded, title: 'No devices used', message: 'Nothing was played in this period.')
      else
        Gap(
          LiquidGlassSurface(
            child: Column(
              children: [
                for (final d in stats.devices) ...[
                  Row(
                    children: [
                      Icon(deviceIcon(d.connectionType), size: 18, color: p.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DataVisualizationBar(
                          percentage: stats.total.inSeconds == 0 ? 0 : d.listening.inSeconds / stats.total.inSeconds,
                          label: d.name,
                          valueText: '${Fmt.duration(d.listening)} · ${Fmt.percent(stats.total.inSeconds == 0 ? 0 : d.listening.inSeconds / stats.total.inSeconds)}',
                        ),
                      ),
                    ],
                  ),
                  if (d != stats.devices.last) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}
