import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/eartime_event.dart';

/// One raw tracking event in the History → Events log.
class TimelineEventCard extends StatelessWidget {
  final EarTimeEvent event;
  final String deviceName;

  const TimelineEventCard({super.key, required this.event, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    final (IconData icon, String title, Color color) = switch (event.eventType) {
      'DEVICE_CONNECTED' => (Icons.bluetooth_connected_rounded, 'Connected', p.success),
      'DEVICE_DISCONNECTED' => (Icons.bluetooth_disabled_rounded, 'Disconnected', p.textSecondary),
      'PLAYBACK_STARTED' || 'PLAYBACK_RESUMED' => (Icons.play_arrow_rounded, 'Playback started', p.accent),
      'PLAYBACK_PAUSED' || 'PLAYBACK_STOPPED' => (Icons.pause_rounded, 'Playback paused', p.textSecondary),
      'VOLUME_CHANGED' => (Icons.volume_up_rounded, 'Volume ${event.volumePercent ?? '?'}%', p.warning),
      _ => (Icons.event_note_rounded, event.eventType, p.textSecondary),
    };
    final detail = [
      deviceName,
      if (event.volumePercent != null && event.eventType != 'VOLUME_CHANGED') 'vol ${event.volumePercent}%',
      if (event.reason == 'RECOVERED') 'recovered after restart',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.time(event.timestamp), style: theme.textTheme.labelLarge?.copyWith(color: p.textPrimary)),
              Text(Fmt.day(event.timestamp), style: theme.textTheme.labelSmall?.copyWith(color: p.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
