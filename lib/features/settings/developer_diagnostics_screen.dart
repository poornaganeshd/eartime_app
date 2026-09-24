import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/liquid_glass_surface.dart';
import '../../providers/data_providers.dart';
import '../../domain/models/tracking_event.dart';
import '../../domain/logic/capability_detector.dart';
import '../../domain/models/earbud_capabilities.dart';

class DeveloperDiagnosticsScreen extends ConsumerStatefulWidget {
  const DeveloperDiagnosticsScreen({super.key});

  @override
  ConsumerState<DeveloperDiagnosticsScreen> createState() => _DeveloperDiagnosticsScreenState();
}

class _LogEntry {
  final DateTime timestamp;
  final String label;
  final TrackingEvent? event;
  final bool isAction;

  _LogEntry({
    required this.timestamp,
    required this.label,
    this.event,
    this.isAction = false,
  });
}

class _DeveloperDiagnosticsScreenState extends ConsumerState<DeveloperDiagnosticsScreen> {
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  
  String? _lastPayload;
  String? _lastAction;
  String? _diffResult;

  String _gattState = 'Unknown';
  String? _gattMessage;

  @override
  void initState() {
    super.initState();
    // Trigger BLE diagnostic for the currently active device, if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeDevice = ref.read(liveSessionProvider).activeDevice;
      if (activeDevice != null && activeDevice.canonicalDeviceId.contains(':')) {
        _logAction('TRIGGERING NATIVE BLE DIAGNOSTIC FOR ${activeDevice.canonicalDeviceId}');
        ref.read(trackingPlatformProvider).startBleDiagnostic(activeDevice.canonicalDeviceId);
      }
    });
  }

  void _logAction(String actionName) {
    setState(() {
      _lastAction = actionName;
      _logs.add(_LogEntry(
        timestamp: DateTime.now(),
        label: '[ACTION] $actionName',
        isAction: true,
      ));
    });
    _scrollToBottom();
  }

  void _handleBleEvent(TrackingEvent event) {
    final payload = event.payload;
    if (payload == null) return;

    if (_lastAction != null && _lastPayload != null) {
      final before = _lastPayload!;
      final after = payload;
      
      if (before != after) {
        String diffText = 'POSSIBLE STATE CHANGE\nObserved during: $_lastAction\nConfidence: UNCONFIRMED\n';
        for (int i = 0; i < before.length && i < after.length; i += 2) {
          final bByte = before.substring(i, i + 2);
          final aByte = after.substring(i, i + 2);
          if (bByte != aByte) {
            diffText += 'Candidate field changed after $_lastAction:\nByte offset ${i ~/ 2}\nBefore: $bByte\nAfter:  $aByte\n\n';
          }
        }
        setState(() {
          _diffResult = diffText;
        });
      }
      
      _lastAction = null;
    }

    _lastPayload = payload;

    setState(() {
      _logs.add(_LogEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(event.timestamp),
        label: '[BLE-NOTIFY] Uninterpreted OPOv1 notification. Char: ${event.characteristicUuid?.substring(0, 8)}... Payload: $payload',
        event: event,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Listen to capability detection service instantiation
    ref.watch(capabilityDetectorServiceProvider);
    
    // Listen to BLE notifications
    ref.listen<AsyncValue<TrackingEvent>>(bleNotificationProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _handleBleEvent(next.value!);
      }
    });

    final capabilities = ref.watch(earbudCapabilitiesProvider);
    final discoveryResult = ref.watch(bleDiscoveryResultProvider);

    ref.listen<AsyncValue<TrackingEvent>>(bleDiagnosticStateProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final event = next.value!;
        setState(() {
          _gattState = event.state ?? 'UNKNOWN';
          if (event.message != null) {
            _gattMessage = event.message;
          }
          _logs.add(_LogEntry(
            timestamp: DateTime.fromMillisecondsSinceEpoch(event.timestamp),
            label: '[GATT STATE] $_gattState${event.message != null ? ' - ${event.message}' : ''}',
            isAction: true, // Make it pop visually
          ));
        });
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earbud Diagnostics', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final activeDevice = ref.read(liveSessionProvider).activeDevice;
              if (activeDevice != null && activeDevice.canonicalDeviceId.isNotEmpty) {
                setState(() {
                  _gattState = 'REFRESHING...';
                  _gattMessage = null;
                });
                ref.read(trackingPlatformProvider).startBleDiagnostic(activeDevice.canonicalDeviceId);
              }
            },
            child: const Text('Refresh Diagnostic', style: TextStyle(color: AppColors.editorialWhite)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 30),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDeviceSection(theme, discoveryResult.value),
                  const SizedBox(height: 16),
                  _buildCapabilitiesSection(theme, capabilities),
                  const SizedBox(height: 16),
                  _buildServicesSection(theme, discoveryResult.value),
                  const SizedBox(height: 16),
                  _buildTestControls(theme),
                  const SizedBox(height: 16),
                  _buildLogList(theme),
                  if (_diffResult != null) _buildDiffAnalyzerPanel(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceSection(ThemeData theme, Map<String, dynamic>? discoveryResult) {
    final activeDevice = ref.watch(liveSessionProvider).activeDevice;
    
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEVICE', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.editorialWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Name: ${activeDevice?.displayName ?? 'Unknown'}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          Text('Address: ${activeDevice?.canonicalDeviceId ?? 'Unknown'}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('GATT Connected: $_gattState', 
            style: theme.textTheme.bodySmall?.copyWith(
              color: _gattState == 'CONNECTED' || _gattState == 'SERVICES_DISCOVERED' ? AppColors.primary : AppColors.error
            )
          ),
          if (_gattMessage != null) 
            Text('Message: $_gattMessage', style: const TextStyle(fontSize: 10, color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection(ThemeData theme, EarbudCapabilities caps) {
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAPABILITIES', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.editorialWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _capRow('Active Provider:', caps.providerName, isHighlight: true),
          _capRow('BLE Available:', caps.bleAvailable.name.toUpperCase()),
          _capRow('GATT Available:', caps.gattAvailable.name.toUpperCase()),
          _capRow('LE Audio (PACS):', caps.leAudioAvailable.name.toUpperCase()),
          _capRow('Individual Bud Identity:', caps.individualBudIdentity.name.toUpperCase()),
          _capRow('Left/Right Identity:', caps.leftRightIdentity.name.toUpperCase()),
          _capRow('Left/Right Connection:', caps.leftRightConnectionState.name.toUpperCase()),
          _capRow('In-Ear Detection:', caps.inEarDetection.name.toUpperCase()),
          _capRow('Per-Ear Exposure:', caps.perEarExposure.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _capRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          Text(
            value, 
            style: TextStyle(
              fontSize: 12, 
              color: isHighlight ? AppColors.secondary : (value == 'SUPPORTED' ? AppColors.primary : AppColors.onSurfaceVariant),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(ThemeData theme, Map<String, dynamic>? discoveryResult) {
    if (discoveryResult == null) {
      return const SizedBox.shrink();
    }
    
    // bleDiscoveryResultProvider already yields the inner device map.
    final services = discoveryResult['services'] as List<dynamic>? ?? [];

    return LiquidGlassSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SERVICES & CHARACTERISTICS', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.editorialWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...services.map((s) {
            final chars = s['characteristics'] as List<dynamic>? ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${s['uuid']}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ...chars.map((c) {
                    final props = (c['properties'] as List<dynamic>).join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                      child: Text('Char: ${c['uuid']}\nProps: $props', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestControls(ThemeData theme) {
    return Column(
      children: [
        Text(
          'PHYSICAL EXPERIMENT MARKERS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionButton('BOTH EARBUDS INSERTED')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionButton('LEFT REMOVED')),
            const SizedBox(width: 8),
            Expanded(child: _buildActionButton('LEFT INSERTED')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionButton('RIGHT REMOVED')),
            const SizedBox(width: 8),
            Expanded(child: _buildActionButton('RIGHT INSERTED')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label) {
    return ElevatedButton(
      onPressed: () => _logAction(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.glassBgDark,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogList(ThemeData theme) {
    return LiquidGlassSurface(
      child: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        height: 250, // Fixed height for scrollable log list within ScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RAW OPOv1 OBSERVATION',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.editorialWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final timeStr = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}";
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "$timeStr ${log.label}",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: log.isAction ? AppColors.secondary : AppColors.onSurfaceVariant,
                        fontWeight: log.isAction ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffAnalyzerPanel(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PACKET COMPARISON',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _diffResult!,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.editorialWhite,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
