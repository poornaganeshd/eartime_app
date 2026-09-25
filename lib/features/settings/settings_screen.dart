import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/logic/exposure_math.dart';
import '../../providers/data_providers.dart';
import '../../providers/permission_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/diagnostic_screen.dart';
import '../widgets/ambient_background.dart';
import '../widgets/liquid_glass_surface.dart';
import '../widgets/section_header.dart';
import 'audio_diagnostics_screen.dart';
import 'developer_diagnostics_screen.dart';

export '../../providers/settings_provider.dart' show themeModeProvider;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notificationsGranted;

  @override
  void initState() {
    super.initState();
    _refreshNotificationState();
  }

  Future<void> _refreshNotificationState() async {
    final granted = await ref.read(permissionProvider.notifier).notificationsGranted;
    if (mounted) setState(() => _notificationsGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final prefs = ref.watch(preferencesProvider);
    final settings = ref.read(settingsProvider.notifier);
    final live = ref.watch(liveSessionProvider);
    final platform = ref.read(trackingPlatformProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const SectionHeader(title: 'Monitoring'),
              _Group(children: [
                SwitchListTile(
                  title: const Text('Background monitoring'),
                  subtitle: Text(
                    live.monitoring
                        ? 'Listening time is recorded even when the app is closed.'
                        : 'Paused — nothing is being recorded.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  value: live.monitoring,
                  onChanged: (on) async {
                    if (on) {
                      await platform.startMonitoring();
                    } else {
                      await platform.stopMonitoring();
                    }
                    await platform.requestSync();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.battery_saver_rounded),
                  title: const Text('Keep tracking reliable'),
                  subtitle: Text(
                    'Set battery usage to "Unrestricted" so the phone maker\'s battery saver never stops tracking.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: platform.openBatteryOptimizationSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notifications'),
                  subtitle: Text(
                    _notificationsGranted == false
                        ? 'Off — you won\'t see hearing alerts or the live listening notification.'
                        : 'On — hearing alerts and live listening notification.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  trailing: _notificationsGranted == false
                      ? TextButton(
                          onPressed: () async {
                            await ref.read(permissionProvider.notifier).requestNotifications();
                            await _refreshNotificationState();
                          },
                          child: const Text('Enable'),
                        )
                      : null,
                ),
              ]),
              const SectionHeader(title: 'Hearing'),
              _Group(children: [
                SwitchListTile(
                  title: const Text('Hearing alerts'),
                  subtitle: Text(
                    'Loud listening, break reminders, daily goal and weekly allowance.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  value: prefs.alertsEnabled,
                  onChanged: (v) => settings.update((s) => s.copyWith(alertsEnabled: v)),
                ),
                _SliderTile(
                  title: 'Headphone max output',
                  help: 'Loudness of your headphones at 100% volume. Most earbuds are 95–105 dB; '
                      'raise it for powerful headphones.',
                  value: prefs.maxOutputDb,
                  min: 80,
                  max: 115,
                  divisions: 35,
                  format: (v) => '${v.round()} dB',
                  onChanged: (v) => settings.update((s) => s.copyWith(maxOutputDb: v.roundToDouble())),
                ),
                _SliderTile(
                  title: 'Loud-listening alert',
                  help: 'Alert after 3 minutes at or above this level. '
                      'Safe time at ${prefs.loudThresholdDb.round()} dB is about '
                      '${ExposureMath.dailyAllowance(prefs.loudThresholdDb).inMinutes} min/day.',
                  value: prefs.loudThresholdDb,
                  min: 80,
                  max: 100,
                  divisions: 20,
                  format: (v) => '${v.round()} dB',
                  onChanged: (v) => settings.update((s) => s.copyWith(loudThresholdDb: v.roundToDouble())),
                ),
                _ChoiceTile(
                  title: 'Break reminder',
                  help: 'Reminds you to rest your ears after continuous listening.',
                  value: prefs.breakReminderMinutes,
                  options: const {0: 'Off', 30: '30m', 45: '45m', 60: '60m', 90: '90m'},
                  onChanged: (v) => settings.update((s) => s.copyWith(breakReminderMinutes: v)),
                ),
                _ChoiceTile(
                  title: 'Daily listening goal',
                  help: 'Shown on the home ring; you get one alert when you pass it.',
                  value: prefs.dailyLimitMinutes,
                  options: const {0: 'Off', 60: '1h', 120: '2h', 180: '3h', 240: '4h', 360: '6h'},
                  onChanged: (v) => settings.update((s) => s.copyWith(dailyLimitMinutes: v)),
                ),
              ]),
              const SectionHeader(title: 'Appearance'),
              _Group(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                      ],
                      selected: {prefs.themeMode},
                      onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    ),
                  ),
                ),
              ]),
              const SectionHeader(title: 'Data'),
              _Group(children: [
                ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  title: const Text('Copy history as CSV'),
                  subtitle: Text('Paste into a spreadsheet or notes app.', style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
                  onTap: () => _exportCsv(context),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: p.danger),
                  title: Text('Clear listening history', style: TextStyle(color: p.danger)),
                  onTap: () => _confirmClear(context),
                ),
              ]),
              const SectionHeader(title: 'Developer'),
              _Group(children: [
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: const Text('Live pipeline state'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDark(context, const DiagnosticScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.speaker_group_outlined),
                  title: const Text('Audio routing diagnostics'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDark(context, const AudioDiagnosticsScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Earbud BLE diagnostics'),
                  subtitle: Text('Per-ear protocol capabilities and telemetry', style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDark(context, const DeveloperDiagnosticsScreen()),
                ),
              ]),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'EarTime 1.1 · Levels are estimates, not a medical measurement.',
                  style: theme.textTheme.bodySmall?.copyWith(color: p.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diagnostics screens use the fixed dark developer palette regardless of the app theme.
  void _openDark(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Theme(data: AppTheme.darkTheme, child: screen)));
  }

  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final rows = await db.getAllEvents();
    final buffer = StringBuffer('timestamp,event,device_id,device_name,connection,volume_percent,attenuation_db,reason\n');
    String esc(String? v) => v == null ? '' : '"${v.replaceAll('"', '""')}"';
    for (final r in rows) {
      buffer.writeln([
        DateTime.fromMillisecondsSinceEpoch(r.timestamp).toIso8601String(),
        r.eventType,
        esc(r.canonicalDeviceId),
        esc(r.deviceName),
        r.connectionType,
        r.volumePercent ?? '',
        r.attenuationDb?.toStringAsFixed(1) ?? '',
        r.reason ?? '',
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    messenger.showSnackBar(SnackBar(content: Text('Copied ${rows.length} events to the clipboard')));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear listening history?'),
        content: const Text('All recorded sessions and exposure data will be permanently deleted from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).clearAllEvents();
    messenger.showSnackBar(const SnackBar(content: Text('History cleared')));
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassSurface(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const Divider(indent: 16, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatefulWidget {
  final String title;
  final String help;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.help,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final v = (_dragging ?? widget.value).clamp(widget.min, widget.max);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: theme.textTheme.bodyLarge)),
              Text(widget.format(v), style: theme.textTheme.labelLarge?.copyWith(color: p.accent)),
            ],
          ),
          Slider(
            value: v,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.format(v),
            onChanged: (x) => setState(() => _dragging = x),
            onChangeEnd: (x) {
              setState(() => _dragging = null);
              widget.onChanged(x);
            },
          ),
          Text(widget.help, style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String help;
  final int value;
  final Map<int, String> options;
  final ValueChanged<int> onChanged;

  const _ChoiceTile({
    required this.title,
    required this.help,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(help, style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  onSelected: (_) => onChanged(e.key),
                  showCheckmark: false,
                  selectedColor: p.accent.withValues(alpha: 0.2),
                  side: BorderSide(color: value == e.key ? p.accent : p.border),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
