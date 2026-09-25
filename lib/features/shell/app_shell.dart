import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_providers.dart';
import '../../providers/permission_provider.dart';
import '../analytics/analytics_screen.dart';
import '../devices/devices_screen.dart';
import '../home/home_screen.dart';
import '../permissions/permission_screen.dart';
import '../settings/settings_screen.dart';
import '../timeline/timeline_screen.dart';
import '../wellbeing/wellbeing_screen.dart';
import '../widgets/glass_navigation.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  late final AppLifecycleListener _lifecycle;

  static const _destinations = [
    NavDestination(Icons.graphic_eq_outlined, Icons.graphic_eq_rounded, 'Now'),
    NavDestination(Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
    NavDestination(Icons.history_outlined, Icons.history_rounded, 'History'),
    NavDestination(Icons.hearing_outlined, Icons.hearing_rounded, 'Hearing'),
    NavDestination(Icons.headphones_outlined, Icons.headphones_rounded, 'Devices'),
  ];

  @override
  void initState() {
    super.initState();
    // Coming back to the foreground: permissions may have changed in system settings, and the
    // engine may have journaled events while the UI was paused.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    unawaited(ref.read(permissionProvider.notifier).checkPermissions());
    if (ref.read(permissionProvider) == PermissionStatusState.granted) {
      unawaited(ref.read(trackingPlatformProvider).requestSync());
      unawaited(ref.read(eventIngestorProvider).drain());
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionProvider);
    if (permissionState != PermissionStatusState.granted) {
      return const PermissionScreen();
    }

    // Wake the passive real-time pipeline only once permissions are granted.
    ref.watch(trackingPipelineProvider);

    final screens = [
      HomeScreen(onOpenSettings: _openSettings, onOpenHearing: () => setState(() => _currentIndex = 3)),
      AnalyticsScreen(onOpenSettings: _openSettings),
      TimelineScreen(onOpenSettings: _openSettings),
      WellbeingScreen(onOpenSettings: _openSettings),
      DevicesScreen(onOpenSettings: _openSettings),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: GlassNavigation(
        currentIndex: _currentIndex,
        destinations: _destinations,
        onIndexChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
