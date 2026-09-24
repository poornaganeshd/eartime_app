import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/logic/exposure_math.dart';
import '../../domain/logic/listening_analyzer.dart';
import '../../domain/models/listening_session.dart';
import '../../domain/models/live_session_state.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../widgets/charts.dart';
import '../widgets/editorial_metric.dart';
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import '../widgets/status_indicator.dart';
import '../widgets/tab_page.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenHearing;

  const HomeScreen({super.key, this.onOpenSettings, this.onOpenHearing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return TabPage(
      onOpenSettings: onOpenSettings,
      onRefresh: () async {
        await ref.read(trackingPlatformProvider).requestSync();
        await ref.read(eventIngestorProvider).drain();
      },
      slivers: [
        SliverToBoxAdapter(
          child: ScreenTitle(
            eyebrow: '${Fmt.greeting(now)} · ${Fmt.day(now)}',
            title: live.isPlaying ? 'Listening now' : (live.hasDevice ? 'Headphones ready' : 'Ready when you are'),
          ),
        ),
        SliverToBoxAdapter(child: Gap(_StatusRow(live: live))),
        if (live.isInitialized && !live.monitoring) const SliverToBoxAdapter(child: Gap(_MonitoringOffCard())),
        if (live.lastAlert != null) SliverToBoxAdapter(child: Gap(_AlertBanner(message: live.lastAlert!))),
        const SliverToBoxAdapter(child: Gap(_TodayHero())),
        SliverToBoxAdapter(child: Gap(_LiveDeviceCard(live: live, now: now))),
        SliverToBoxAdapter(child: Gap(_HearingSnapshot(onTap: onOpenHearing))),
        const SliverToBoxAdapter(child: Gap(_TodayMetrics())),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Recent sessions')),
        const _RecentSessions(),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final LiveSessionState live;

  const _StatusRow({required this.live});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, color, active) = !live.isInitialized
        ? ('Connecting to tracker', p.textTertiary, false)
        : !live.monitoring
            ? ('Monitoring paused', p.warning, true)
            : live.isPlaying
                ? ('Live', p.success, true)
                : live.hasDevice
                    ? ('Connected · idle', p.accent, true)
                    : ('No headphones', p.textTertiary, false);
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusIndicator(isActive: active, label: label, color: color, pulse: live.isPlaying),
    );
  }
}

class _MonitoringOffCard extends ConsumerWidget {
  const _MonitoringOffCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return LiquidGlassSurface(
      tint: p.warning,
      child: Row(
        children: [
          Icon(Icons.pause_circle_outline_rounded, color: p.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Background monitoring is off, so listening time is not being recorded.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(trackingPlatformProvider).startMonitoring(),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;

  const _AlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LiquidGlassSurface(
      tint: p.warning,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hearing_disabled_rounded, color: p.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _TodayHero extends ConsumerWidget {
  const _TodayHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final stats = ref.watch(statsProvider(StatsRange.today));
    final goal = ref.watch(preferencesProvider.select((s) => s.dailyLimitMinutes));
    final total = stats.value?.total ?? Duration.zero;
    final progress = goal > 0 ? total.inSeconds / (goal * 60) : 0.0;

    return LiquidGlassSurface(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: ProgressRing(
          progress: progress,
          size: 236,
          semanticsLabel: 'Listened ${Fmt.duration(total)} today'
              '${goal > 0 ? ' of a ${Fmt.duration(Duration(minutes: goal))} goal' : ''}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TODAY', style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stats.isLoading && !stats.hasValue ? '--:--:--' : Fmt.clock(total),
                  style: theme.textTheme.displayMedium?.copyWith(fontFeatures: tabularFigures),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                goal > 0 ? '${Fmt.percent(progress)} of ${Fmt.duration(Duration(minutes: goal))} goal' : 'No daily goal',
                style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData deviceIcon(String connectionType) => switch (connectionType) {
      'wired' => Icons.cable_rounded,
      'usb' => Icons.usb_rounded,
      'hearing_aid' => Icons.hearing_rounded,
      _ => Icons.headphones_rounded,
    };

class _LiveDeviceCard extends ConsumerWidget {
  final LiveSessionState live;
  final DateTime now;

  const _LiveDeviceCard({required this.live, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final device = live.activeDevice;
    if (device == null) {
      return LiquidGlassSurface(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: p.surfaceHigh, shape: BoxShape.circle),
              child: Icon(Icons.headphones_outlined, color: p.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No headphones connected', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Connect Bluetooth, wired or USB headphones — tracking starts automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final maxOutput = ref.watch(preferencesProvider.select((s) => s.maxOutputDb));
    final volume = live.volume;
    final db = ExposureMath.estimatedDb(maxOutput, volume?.attenuationDb);
    final interval = live.currentIntervalAt(now);
    final others = live.connectedDevices.where((d) => d.canonicalDeviceId != device.canonicalDeviceId).toList();

    return LiquidGlassSurface(
      tint: live.isPlaying ? p.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (live.isPlaying ? p.accent : p.textSecondary).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(deviceIcon(device.deviceType), color: live.isPlaying ? p.accent : p.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live.isPlaying ? 'NOW PLAYING' : 'CONNECTED · NOT PLAYING',
                      style: theme.textTheme.labelMedium?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(device.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          EditorialMetric(
            label: live.isPlaying ? 'Playing for' : 'Paused',
            value: live.isPlaying ? Fmt.clock(interval) : '--:--:--',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EditorialMetric(
                  label: 'Volume',
                  value: volume == null ? '--' : '${volume.percent}',
                  unit: volume == null ? null : '%',
                  icon: Icons.volume_up_rounded,
                ),
              ),
              Expanded(
                child: EditorialMetric(
                  label: 'Level',
                  value: volume == null || db <= 0 ? '--' : '~${db.round()}',
                  unit: volume == null || db <= 0 ? null : 'dB',
                  icon: Icons.graphic_eq_rounded,
                ),
              ),
            ],
          ),
          if (volume != null && db > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: p.forLevel(db))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${EarPalette.levelLabel(db)} · safe for about '
                    '${Fmt.duration(ExposureMath.dailyAllowance(db))} a day at this level',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (others.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Also connected: ${others.map((d) => d.displayName).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(color: p.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _HearingSnapshot extends ConsumerWidget {
  final VoidCallback? onTap;

  const _HearingSnapshot({this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(statsProvider(StatsRange.week)).value;
    final today = ref.watch(statsProvider(StatsRange.today)).value;
    final dose = week?.dose ?? 0;
    return LiquidGlassSurface(
      onTap: onTap,
      semanticLabel: 'Open hearing details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AllowanceMeter(
            fraction: dose,
            label: 'Weekly sound allowance',
            caption: 'WHO safe-listening dose over the last 7 days (80 dB for 40 h/week).',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: EditorialMetric(
                  label: 'Avg today',
                  value: today?.averageDb == null ? '--' : '${today!.averageDb!.round()}',
                  unit: today?.averageDb == null ? null : 'dB',
                ),
              ),
              Expanded(
                child: EditorialMetric(
                  label: 'Peak today',
                  value: today?.peakDb == null ? '--' : '${today!.peakDb!.round()}',
                  unit: today?.peakDb == null ? null : 'dB',
                ),
              ),
              Expanded(
                child: EditorialMetric(label: 'Loud time', value: Fmt.duration(today?.loudTime ?? Duration.zero)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayMetrics extends ConsumerWidget {
  const _TodayMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(statsProvider(StatsRange.today)).value;
    return Row(
      children: [
        Expanded(
          child: LiquidGlassSurface(
            padding: const EdgeInsets.all(16),
            child: EditorialMetric(label: 'Sessions', value: '${today?.sessionCount ?? 0}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LiquidGlassSurface(
            padding: const EdgeInsets.all(16),
            child: EditorialMetric(label: 'Longest', value: Fmt.duration(today?.longestContinuous ?? Duration.zero)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LiquidGlassSurface(
            padding: const EdgeInsets.all(16),
            child: EditorialMetric(label: 'Breaks', value: '${today?.breaks ?? 0}'),
          ),
        ),
      ],
    );
  }
}

class _RecentSessions extends ConsumerWidget {
  const _RecentSessions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider(StatsRange.week));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return sessionsAsync.when(
      data: (sessions) {
        final played = sessions.where((s) => s.intervals.isNotEmpty).toList().reversed.take(3).toList();
        if (played.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.music_note_rounded,
              title: 'No sessions yet',
              message: 'Your listening sessions from the last week will appear here.',
            ),
          );
        }
        return SliverList.separated(
          itemCount: played.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => SessionTile(session: played[i], now: now),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(child: Text('Could not load sessions: $e')),
    );
  }
}

/// Compact session row shared by Home and History.
class SessionTile extends ConsumerWidget {
  final ListeningSession session;
  final DateTime now;

  /// Hide the day when the list is already grouped by day.
  final bool showDay;

  const SessionTile({super.key, required this.session, required this.now, this.showDay = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final maxOutput = ref.watch(preferencesProvider.select((s) => s.maxOutputDb));
    final listening = session.listeningAt(now);
    final start = session.firstPlayback ?? session.connectTime;
    final end = session.lastActivity(now) ?? now;
    final live = session.isPlaying;

    // Time-weighted level for this session.
    var energy = 0.0;
    var known = Duration.zero;
    for (final i in session.intervals) {
      final db = ExposureMath.estimatedDb(maxOutput, i.attenuationDb);
      if (i.attenuationDb == null || db <= 0) continue;
      final d = (i.endTime ?? now).difference(i.startTime);
      energy += ExposureMath.energy(db, d);
      known += d;
    }
    final leq = energy > 0 ? ExposureMath.leq(energy, known) : null;

    return LiquidGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (live ? p.success : p.accent).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(live ? Icons.graphic_eq_rounded : deviceIcon(session.connectionType),
                color: live ? p.success : p.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.deviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  '${showDay ? '${Fmt.day(start, now: now)} · ' : ''}${Fmt.time(start)}–${live ? 'now' : Fmt.time(end)}'
                  '${leq == null ? '' : ' · ~${leq.round()} dB'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Fmt.duration(listening, seconds: true),
            style: theme.textTheme.labelLarge?.copyWith(color: p.textPrimary, fontFeatures: tabularFigures),
          ),
        ],
      ),
    );
  }
}
