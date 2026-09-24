import 'package:drift/native.dart';
import 'package:eartime_app/core/theme/app_typography.dart';
import 'package:eartime_app/data/database/database.dart';
import 'package:eartime_app/main.dart';
import 'package:eartime_app/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_tracking_platform.dart';

void main() {
  setUpAll(() => AppTypography.useGoogleFonts = false);

  Future<(FakeTrackingPlatform, AppDatabase)> pumpApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final platform = FakeTrackingPlatform();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        trackingPlatformProvider.overrideWithValue(platform),
        databaseProvider.overrideWithValue(db),
      ],
      child: const EarTimeApp(),
    ));
    // Permission check runs after the first frame (non-Android => granted).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return (platform, db);
  }

  Future<void> teardown(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  testWidgets('EarTimeApp starts on the Now tab with navigation', (tester) async {
    final (platform, db) = await pumpApp(tester);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Ready when you are'), findsOneWidget);
    expect(platform.syncRequests, greaterThan(0));
    await teardown(tester, db);
  });

  testWidgets('live events drive the home screen', (tester) async {
    final (platform, db) = await pumpApp(tester);
    final t = DateTime.now().millisecondsSinceEpoch;
    platform.emitLive({
      'type': 'SYNC_STATE',
      'timestamp': t,
      'monitoring': true,
      'connectedDevices': [device('AA:BB:CC:DD:EE:FF')],
      'activeDeviceId': 'AA:BB:CC:DD:EE:FF',
      'isPlaying': true,
      'playbackStartedAt': t - 5000,
      'volume': volume(60, -17),
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Listening now'), findsOneWidget);
    expect(find.text('Nord Buds 3 Pro'), findsWidgets);
    await teardown(tester, db);
  });

  testWidgets('every tab renders without layout errors on a small phone', (tester) async {
    final (_, db) = await pumpApp(tester, size: const Size(320, 640));
    for (final tab in ['Insights', 'History', 'Hearing', 'Devices', 'Now']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    await teardown(tester, db);
  });

  testWidgets('settings screen opens and renders in light mode', (tester) async {
    final (_, db) = await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Background monitoring'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Light'), find.byType(ListView), const Offset(0, -200));
    await tester.tap(find.text('Light'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(Theme.of(tester.element(find.text('Light'))).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
    await teardown(tester, db);
  });
}
