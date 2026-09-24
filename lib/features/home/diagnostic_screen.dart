import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/data_providers.dart';

class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawEventsAsync = ref.watch(recentEventsProvider); // newest first
    final liveSessionState = ref.watch(liveSessionProvider);
    final activeDevice = liveSessionState.activeDevice;
    final bleDiscoveryAsync = ref.watch(bleDiscoveryResultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Live pipeline state', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.editorialWhite)),
        iconTheme: const IconThemeData(color: AppColors.editorialWhite),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('STATE SUMMARY', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Device: ${activeDevice?.displayName ?? 'None'} (${activeDevice?.canonicalDeviceId ?? 'N/A'}) - ${activeDevice?.playbackState.name ?? 'unknown'}', style: const TextStyle(color: AppColors.secondary)),
                  const SizedBox(height: 6),
                  Text(
                    'initialized=${liveSessionState.isInitialized} monitoring=${liveSessionState.monitoring} '
                    'playing=${liveSessionState.isPlaying} since=${liveSessionState.playbackStartedAt} '
                    'devices=${liveSessionState.connectedDevices.length} volume=${liveSessionState.volume?.percent}% '
                    '(${liveSessionState.volume?.attenuationDb.toStringAsFixed(1)} dB)',
                    style: const TextStyle(color: AppColors.editorialWhite, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('BLE DISCOVERY', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: bleDiscoveryAsync.when(
                  data: (discovery) {
                    if (discovery.isEmpty) {
                      return const Center(child: Text('Awaiting BLE connection...', style: TextStyle(color: AppColors.onSurfaceVariant)));
                    }
                    final services = discovery['services'] as List<dynamic>? ?? [];
                    return ListView.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        final chars = service['characteristics'] as List<dynamic>? ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Service: ${service['uuid']} (${service['type']})', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                              ...chars.map((c) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Text('Char: ${c['uuid']}\nProps: ${c['properties']}', style: const TextStyle(color: AppColors.editorialWhite, fontSize: 12)),
                              )),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('BLE Error: $e', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('RAW EVENT LOG', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: rawEventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Center(child: Text('No events yet.', style: TextStyle(color: AppColors.onSurfaceVariant)));
                    }
                    final latest = events.take(50).toList();
                    return ListView.builder(
                      itemCount: latest.length,
                      itemBuilder: (context, i) {
                        final e = latest[i];
                        return Text(
                          '${e.timestamp.toIso8601String().substring(5, 19)}  ${e.eventType}  ${e.deviceName}'
                          '${e.volumePercent == null ? '' : '  vol=${e.volumePercent}%'}${e.reason == null ? '' : '  (${e.reason})'}',
                          style: const TextStyle(color: AppColors.editorialWhite, fontFamily: 'monospace', fontSize: 11),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: Text('Waiting for events...', style: TextStyle(color: AppColors.onSurfaceVariant))),
                  error: (error, stack) => Text('Error: $error', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
