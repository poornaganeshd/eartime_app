import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/logic/listening_analyzer.dart';
import '../../domain/models/audio_device.dart';
import '../../domain/models/listening_session.dart';
import '../../providers/data_providers.dart';
import '../home/home_screen.dart' show deviceIcon;
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';

class DevicesScreen extends ConsumerWidget {
  final VoidCallback? onOpenSettings;

  const DevicesScreen({super.key, this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final sessionsAsync = ref.watch(sessionsProvider(StatsRange.month));
    final monthStats = ref.watch(statsProvider(StatsRange.month)).value;

    return TabPage(
      onOpenSettings: onOpenSettings,
      orbA: const Alignment(1.3, -0.2),
      orbB: const Alignment(-1.0, 1.1),
      slivers: [
        const SliverToBoxAdapter(child: ScreenTitle(eyebrow: 'Your audio gear', title: 'Devices')),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Connected now')),
        if (live.connectedDevices.isEmpty)
          const SliverToBoxAdapter(
            child: Gap(
              LiquidGlassSurface(
                child: EmptyState(
                  icon: Icons.headphones_outlined,
                  title: 'Nothing connected',
                  message: 'Bluetooth earbuds, headphones, hearing aids, wired and USB headsets are all detected automatically.',
                ),
              ),
            ),
          )
        else
          SliverList.list(
            children: [
              for (final d in live.connectedDevices.reversed)
                Gap(
                  _ConnectedDeviceTile(
                    device: d,
                    playing: live.isPlaying && live.activeDeviceId == d.canonicalDeviceId,
                    now: now,
                  ),
                  after: 10,
                ),
            ],
          ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Last 30 days')),
        sessionsAsync.when(
          data: (sessions) {
            final known = _knownDevices(sessions, monthStats, now);
            if (known.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(icon: Icons.devices_other_rounded, title: 'No devices yet', message: 'Devices you use will be listed here.'),
              );
            }
            return SliverList.list(
              children: [for (final k in known) Gap(_KnownDeviceTile(info: k, now: now, connected: live.connectedDevices.any((d) => d.canonicalDeviceId == k.id)), after: 10)],
            );
          },
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Text('Could not load devices: $e')),
        ),
      ],
    );
  }

  List<_KnownDevice> _knownDevices(List<ListeningSession> sessions, ListeningStats? stats, DateTime now) {
    final byId = <String, _KnownDevice>{};
    for (final s in sessions) {
      final last = s.lastActivity(now) ?? s.connectTime;
      final existing = byId[s.canonicalDeviceId];
      byId[s.canonicalDeviceId] = _KnownDevice(
        id: s.canonicalDeviceId,
        name: s.deviceName,
        connectionType: s.connectionType,
        lastSeen: existing == null || last.isAfter(existing.lastSeen) ? last : existing.lastSeen,
        sessions: (existing?.sessions ?? 0) + 1,
        listening: Duration.zero,
      );
    }
    for (final d in stats?.devices ?? const <DeviceUsage>[]) {
      final k = byId[d.id];
      if (k != null) byId[d.id] = k.copyWithListening(d.listening);
    }
    return byId.values.toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }
}

class _KnownDevice {
  final String id;
  final String name;
  final String connectionType;
  final DateTime lastSeen;
  final int sessions;
  final Duration listening;

  const _KnownDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.lastSeen,
    required this.sessions,
    required this.listening,
  });

  _KnownDevice copyWithListening(Duration d) =>
      _KnownDevice(id: id, name: name, connectionType: connectionType, lastSeen: lastSeen, sessions: sessions, listening: d);
}

String _typeLabel(String t) => switch (t) {
      'wired' => 'Wired',
      'usb' => 'USB',
      'hearing_aid' => 'Hearing aid',
      _ => 'Bluetooth',
    };

class _ConnectedDeviceTile extends StatelessWidget {
  final AudioDevice device;
  final bool playing;
  final DateTime now;

  const _ConnectedDeviceTile({required this.device, required this.playing, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final color = playing ? p.success : p.accent;
    return LiquidGlassSurface(
      tint: color,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(deviceIcon(device.deviceType), color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 6),
                    Text(
                      '${_typeLabel(device.deviceType)} · ${playing ? 'Playing' : 'Connected'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
                if (device.canonicalDeviceId.contains(':')) ...[
                  const SizedBox(height: 2),
                  Text(device.canonicalDeviceId, style: theme.textTheme.labelSmall?.copyWith(color: p.textTertiary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnownDeviceTile extends StatelessWidget {
  final _KnownDevice info;
  final DateTime now;
  final bool connected;

  const _KnownDeviceTile({required this.info, required this.now, required this.connected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.surfaceHigh, shape: BoxShape.circle),
            child: Icon(deviceIcon(info.connectionType), color: p.textSecondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  '${_typeLabel(info.connectionType)} · ${info.sessions} session${info.sessions == 1 ? '' : 's'} · '
                  '${connected ? 'connected' : 'last used ${Fmt.ago(info.lastSeen, now: now)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(Fmt.duration(info.listening), style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
