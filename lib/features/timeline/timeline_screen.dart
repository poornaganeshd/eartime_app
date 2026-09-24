import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/logic/exposure_math.dart';
import '../../domain/logic/listening_analyzer.dart';
import '../../domain/models/listening_session.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart' show SessionTile;
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';
import '../widgets/timeline_event_card.dart';

enum _HistoryView { sessions, events }

class TimelineScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenSettings;

  const TimelineScreen({super.key, this.onOpenSettings});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  _HistoryView _view = _HistoryView.sessions;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      onOpenSettings: widget.onOpenSettings,
      orbA: const Alignment(-1.3, -0.3),
      orbB: const Alignment(1.3, 1.0),
      slivers: [
        const SliverToBoxAdapter(child: ScreenTitle(eyebrow: 'Last 30 days', title: 'History')),
        SliverToBoxAdapter(
          child: Gap(
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_HistoryView>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _HistoryView.sessions, label: Text('Sessions'), icon: Icon(Icons.view_agenda_outlined)),
                  ButtonSegment(value: _HistoryView.events, label: Text('Events'), icon: Icon(Icons.list_alt_rounded)),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ),
          ),
        ),
        if (_view == _HistoryView.sessions) const _SessionsByDay() else const _EventLog(),
      ],
    );
  }
}

class _SessionsByDay extends ConsumerWidget {
  const _SessionsByDay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return ref.watch(sessionsProvider(StatsRange.month)).when(
          data: (sessions) {
            final since = StatsRange.month.startFor(now);
            final played = sessions
                .where((s) => s.intervals.isNotEmpty && (s.lastActivity(now) ?? s.connectTime).isAfter(since))
                .toList()
                .reversed
                .toList();
            if (played.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No listening history yet',
                  message: 'Sessions are recorded automatically whenever audio plays through your headphones.',
                ),
              );
            }
            final groups = <DateTime, List<ListeningSession>>{};
            for (final s in played) {
              final t = s.firstPlayback ?? s.connectTime;
              groups.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(s);
            }
            final items = <Widget>[];
            for (final entry in groups.entries) {
              final dayTotal = entry.value.fold(Duration.zero, (a, s) => a + s.listeningAt(now));
              items.add(SectionHeader(title: Fmt.day(entry.key, now: now), trailing: Fmt.duration(dayTotal)));
              for (final s in entry.value) {
                items.add(Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _showSession(context, s, now),
                    child: SessionTile(session: s, now: now, showDay: false),
                  ),
                ));
              }
            }
            return SliverList.list(children: items);
          },
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Text('Could not load history: $e')),
        );
  }

  void _showSession(BuildContext context, ListeningSession session, DateTime now) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      builder: (_) => _SessionDetail(session: session, now: now),
    );
  }
}

class _SessionDetail extends ConsumerWidget {
  final ListeningSession session;
  final DateTime now;

  const _SessionDetail({required this.session, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final maxOutput = ref.watch(preferencesProvider.select((s) => s.maxOutputDb));
    final end = session.disconnectTime;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(session.deviceName, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Connected ${Fmt.day(session.connectTime, now: now)} ${Fmt.time(session.connectTime)}'
            ' · ${end == null ? 'still connected' : 'disconnected ${Fmt.time(end)}'}',
            style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Text('Listening ${Fmt.duration(session.listeningAt(now), seconds: true)}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Playback stretches'),
          for (final i in session.intervals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LiquidGlassSurface(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Fmt.time(i.startTime)} – ${i.endTime == null ? 'now' : Fmt.time(i.endTime!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (i.attenuationDb != null) ...[
                      Builder(builder: (context) {
                        final db = ExposureMath.estimatedDb(maxOutput, i.attenuationDb);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: p.forLevel(db))),
                            const SizedBox(width: 6),
                            Text('~${db.round()} dB', style: theme.textTheme.labelLarge?.copyWith(color: p.textSecondary)),
                          ],
                        );
                      }),
                      const SizedBox(width: 12),
                    ],
                    Text(Fmt.duration((i.endTime ?? now).difference(i.startTime), seconds: true),
                        style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventLog extends ConsumerWidget {
  const _EventLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(recentEventsProvider).when(
          data: (events) {
            if (events.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(icon: Icons.list_alt_rounded, title: 'No events yet', message: 'Connect headphones to start.'),
              );
            }
            return SliverToBoxAdapter(
              child: LiquidGlassSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final e in events.take(300)) TimelineEventCard(event: e, deviceName: e.deviceName),
                  ],
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Text('Could not load events: $e')),
        );
  }
}
