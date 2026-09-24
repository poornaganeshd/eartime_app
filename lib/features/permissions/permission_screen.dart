import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/data_providers.dart';
import '../../providers/permission_provider.dart';
import '../widgets/ambient_background.dart';
import '../widgets/liquid_glass_surface.dart';

/// Onboarding gate: explains why each permission is needed, then requests it.
class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final state = ref.watch(permissionProvider);
    final notifier = ref.read(permissionProvider.notifier);

    Future<void> onPressed() async {
      if (state == PermissionStatusState.permanentlyDenied) {
        await openAppSettings();
        return;
      }
      final granted = await notifier.requestPermissions();
      if (granted) {
        await ref.read(trackingPlatformProvider).startMonitoring();
      }
    }

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.graphic_eq_rounded, size: 34, color: p.accent),
                      ),
                      const SizedBox(height: 24),
                      Text('Welcome to EarTime', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 12),
                      Text(
                        'Screen Time for your ears: EarTime measures how long and how loud you listen through your '
                        'headphones — automatically, in the background, entirely on your device.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: p.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      const _Reason(
                        icon: Icons.bluetooth_audio_rounded,
                        title: 'Nearby devices (required)',
                        body: 'To recognise your earbuds by name and know when they connect or disconnect.',
                      ),
                      const SizedBox(height: 12),
                      const _Reason(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications (recommended)',
                        body: 'For the live listening notification and hearing-safety alerts. You can skip this.',
                      ),
                      const SizedBox(height: 12),
                      const _Reason(
                        icon: Icons.lock_outline_rounded,
                        title: 'Private by design',
                        body: 'No microphone access, no account, nothing leaves your phone.',
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      if (state == PermissionStatusState.denied || state == PermissionStatusState.permanentlyDenied)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: LiquidGlassSurface(
                            tint: p.danger,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: p.danger),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state == PermissionStatusState.permanentlyDenied
                                        ? 'Nearby devices permission is blocked. Open Settings → Permissions → Nearby devices → Allow.'
                                        : 'EarTime can\'t detect your headphones without the Nearby devices permission.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (state == PermissionStatusState.checking)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton(
                          onPressed: onPressed,
                          child: Text(state == PermissionStatusState.permanentlyDenied ? 'Open Settings' : 'Allow and start'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Reason({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
