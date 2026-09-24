import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/liquid_glass_surface.dart';
import '../../providers/data_providers.dart';

class AudioDiagnosticsScreen extends ConsumerStatefulWidget {
  const AudioDiagnosticsScreen({super.key});

  @override
  ConsumerState<AudioDiagnosticsScreen> createState() => _AudioDiagnosticsScreenState();
}

class _AudioDiagnosticsScreenState extends ConsumerState<AudioDiagnosticsScreen> {
  Map<String, dynamic>? _diagData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ref.read(trackingPlatformProvider).getAudioDiagnostics();
      if (!mounted) return;
      setState(() {
        _diagData = data;
      });
    } catch (e) {
      debugPrint("Diag error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bleResultAsync = ref.watch(bleDiscoveryResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio / Earbud Diagnostics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 30),
                ],
              ),
            ),
          ),
          SafeArea(
            child: _isLoading && _diagData == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      _buildSectionHeader(theme, 'SYSTEM'),
                      _buildDataBox(
                        'Android Version: ${_diagData?['androidVersion'] ?? 'N/A'}\n'
                        'API Level: ${_diagData?['apiLevel'] ?? 'N/A'}',
                      ),
                      
                      _buildSectionHeader(theme, 'PERMISSIONS'),
                      _buildDataBox(
                        'BLUETOOTH_CONNECT: ${_diagData?['hasBluetoothConnect'] ?? false}\n'
                        'BLUETOOTH_SCAN: ${_diagData?['hasBluetoothScan'] ?? false}\n'
                        'FOREGROUND_SERVICE_CONNECTED_DEVICE: ${_diagData?['hasFgServiceConnectedDevice'] ?? false}',
                      ),

                      _buildSectionHeader(theme, 'BLUETOOTH'),
                      _buildDataBox(
                        'Adapter State: ${_diagData?['bluetoothAdapterState'] ?? 'N/A'}\n'
                        'Connected A2DP Count: ${_diagData?['a2dpConnectedCount'] ?? 0}\n'
                        'Connected A2DP Names: ${(_diagData?['a2dpConnectedNames'] as List<dynamic>?)?.join(", ") ?? "None"}',
                      ),

                      _buildSectionHeader(theme, 'AUDIO MANAGER (Outputs)'),
                      if (_diagData?['audioManagerDevices'] != null)
                        ...(_diagData!['audioManagerDevices'] as List<dynamic>).map((d) {
                          final map = d as Map<dynamic, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildDataBox(
                              'Product: ${map['productName']}\n'
                              'Type: ${map['type']}\n'
                              'Address: ${map['address']}\n'
                              'ID: ${map['id']}\n'
                              'isSink: ${map['isSink']}\n'
                              'isSource: ${map['isSource']}',
                            ),
                          );
                        }),

                      _buildSectionHeader(theme, 'PER-EAR CAPABILITY DIAGNOSTIC (BLE/GATT)'),
                      bleResultAsync.when(
                        data: (bleData) {
                          if (bleData.isEmpty) {
                            return _buildDataBox('No BLE GATT discovery data available. Connect earbuds to scan.');
                          }
                          
                          // Check if it's the expected OnePlus buds or similar
                          final capabilities = {
                            "Individual bud identity": "UNKNOWN",
                            "Left/Right designation": "UNKNOWN",
                            "Individual connection state": "UNKNOWN",
                            "Individual wear state": "UNKNOWN",
                            "Individual battery state": "UNKNOWN",
                          };

                          final rawServices = (bleData['services'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];
                          
                          if (rawServices.isNotEmpty) {
                             capabilities["Individual bud identity"] = "UNSUPPORTED";
                             capabilities["Left/Right designation"] = "UNSUPPORTED";
                             capabilities["Individual connection state"] = "UNSUPPORTED";
                             capabilities["Individual wear state"] = "UNSUPPORTED";
                             capabilities["Individual battery state"] = "UNSUPPORTED";
                          }

                          // If we find specific vendor characteristics in the future, we can update these

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...capabilities.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(color: AppColors.editorialWhite)),
                                    Text(e.value, style: TextStyle(
                                      color: e.value == 'SUPPORTED' ? AppColors.secondary : AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 16),
                              const Text('RAW GATT DISCOVERY:', style: TextStyle(color: AppColors.primary)),
                              const SizedBox(height: 8),
                              ...rawServices.map((service) {
                                final chars = (service['characteristics'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];
                                final charLines = chars
                                    .map((c) => '  Char: ${c['uuid']}\n    Props: ${(c['properties'] as List<dynamic>?)?.join(", ")}')
                                    .join('\n');
                                return _buildDataBox('Service: ${service['uuid']}\n$charLines');
                              }),
                            ],
                          );
                        },
                        loading: () => _buildDataBox('Waiting for BLE scan...'),
                        error: (e, st) => _buildDataBox('Error reading BLE data: $e'),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader(theme, 'TEST PROCEDURE'),
                      _buildDataBox(
                        'STEP 1: Connect BOTH earbuds.\n'
                        'STEP 2: Remove LEFT earbud. Press Refresh Diagnostic. Show whether anything changed.\n'
                        'STEP 3: Insert LEFT again. Press Refresh Diagnostic.\n'
                        'STEP 4: Remove RIGHT earbud. Press Refresh Diagnostic.\n'
                        'STEP 5: Insert RIGHT again. Press Refresh Diagnostic.\n'
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _refreshDiagnostics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Refresh Diagnostic', style: TextStyle(color: AppColors.editorialWhite)),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionHeader(theme, 'DIAGNOSTIC RESULT'),
                      LiquidGlassSurface(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'PER-EAR TRACKING FEASIBILITY',
                              style: TextStyle(
                                color: AppColors.editorialWhite,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bleResultAsync.asData?.value.isNotEmpty == true
                                  ? 'UNKNOWN'
                                  : 'NOT EXPOSED',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bleResultAsync.asData?.value.isNotEmpty == true
                                  ? 'Android exposes the connected A2DP device and GATT services, but independent left/right state has not yet been identified in the exposed UUIDs.'
                                  : 'Independent left/right state is not currently exposed through accessible Bluetooth/GATT interfaces.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDataBox(String text) {
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: AppColors.editorialWhite,
          fontSize: 12,
        ),
      ),
    );
  }
}
