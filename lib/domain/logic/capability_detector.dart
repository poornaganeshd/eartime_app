import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../models/earbud_capabilities.dart';
import '../providers/ear_state_provider.dart';

class EarbudCapabilitiesNotifier extends Notifier<EarbudCapabilities> {
  @override
  EarbudCapabilities build() => const EarbudCapabilities(providerName: 'Initializing...');
  @override
  set state(EarbudCapabilities value) => super.state = value;
}

final earbudCapabilitiesProvider = NotifierProvider<EarbudCapabilitiesNotifier, EarbudCapabilities>(EarbudCapabilitiesNotifier.new);

class ActiveEarStateProviderNotifier extends Notifier<EarStateProvider?> {
  @override
  EarStateProvider? build() => null;
  @override
  set state(EarStateProvider? value) => super.state = value;
}

final activeEarStateProviderProvider = NotifierProvider<ActiveEarStateProviderNotifier, EarStateProvider?>(ActiveEarStateProviderNotifier.new);

// A service that listens to the raw BLE discovery and selects the right provider
class CapabilityDetectorService {
  final Ref ref;

  CapabilityDetectorService(this.ref) {
    _init();
  }

  void _init() {
    ref.listen(bleDiscoveryResultProvider, (previous, next) async {
      if (next.hasValue && next.value != null) {
        await _evaluateCapabilities(next.value!);
      }
    });

    ref.listen(bleNotificationProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final activeProvider = ref.read(activeEarStateProviderProvider);
        activeProvider?.processNotification(next.value!);
      }
    });
  }

  Future<void> _evaluateCapabilities(Map<String, dynamic> discoveryResult) async {
    final deviceName = discoveryResult['deviceName'] ?? 'Unknown';
    final deviceAddress = discoveryResult['deviceAddress'] ?? 'Unknown';
    final services = discoveryResult['services'] as List<dynamic>? ?? [];
    
    debugPrint('[CAPABILITY PIPELINE] Discovery result received');
    debugPrint('[CAPABILITY PIPELINE] Device=$deviceName');
    debugPrint('[CAPABILITY PIPELINE] Address=$deviceAddress');
    debugPrint('[CAPABILITY PIPELINE] Service count=${services.length}');

    debugPrint('[CAPABILITY] Evaluating providers');

    // 1. Try LE Audio PACS
    try {
      debugPrint('[CAPABILITY] Testing LeAudioPacsProvider');
      final pacs = LeAudioPacsProvider();
      final caps = await pacs.detectCapabilities(discoveryResult); // Will throw if not found
      ref.read(earbudCapabilitiesProvider.notifier).state = caps;
      ref.read(activeEarStateProviderProvider.notifier).state = pacs;
      debugPrint('[CAPABILITY] LE AUDIO PACS PROVIDER SELECTED');
      return;
    } catch (_) {}

    // 2. Try OPOv1
    try {
      debugPrint('[CAPABILITY] Testing OpoV1Provider');
      final opo = OpoV1Provider();
      final caps = await opo.detectCapabilities(discoveryResult); // Will throw if not found
      ref.read(earbudCapabilitiesProvider.notifier).state = caps;
      ref.read(activeEarStateProviderProvider.notifier).state = opo;
      debugPrint('[CAPABILITY] OPOV1 PROVIDER SELECTED');
      return;
    } catch (_) {}

    // 3. Fallback
    debugPrint('[CAPABILITY] Testing FallbackEarStateProvider');
    final fallback = FallbackEarStateProvider();
    final fallbackCaps = await fallback.detectCapabilities(discoveryResult);
    ref.read(earbudCapabilitiesProvider.notifier).state = fallbackCaps;
    ref.read(activeEarStateProviderProvider.notifier).state = fallback;
    debugPrint('[CAPABILITY] FALLBACK PROVIDER SELECTED');
  }
}

final capabilityDetectorServiceProvider = Provider((ref) {
  return CapabilityDetectorService(ref);
});
