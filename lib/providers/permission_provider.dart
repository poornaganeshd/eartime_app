import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionStatusState {
  checking,
  granted,
  denied,

  /// Denied with "don't ask again" — only the system settings screen can grant it now.
  permanentlyDenied,
}

/// Gates the app on the one permission tracking cannot work without: BLUETOOTH_CONNECT
/// (Android 12+; implicitly granted on older releases).
///
/// Notifications are requested but *optional*: without them Android still runs the foreground
/// service, the user just doesn't see the live notification or hearing alerts. Previously a
/// missing notification permission locked users out of the whole app.
class PermissionNotifier extends Notifier<PermissionStatusState> {
  @override
  PermissionStatusState build() {
    // Check after the first frame so the engine never blocks on a platform call during startup.
    WidgetsBinding.instance.addPostFrameCallback((_) => checkPermissions());
    return PermissionStatusState.checking;
  }

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> checkPermissions() async {
    if (!_isAndroid) {
      state = PermissionStatusState.granted;
      return;
    }
    try {
      final status = await Permission.bluetoothConnect.status;
      state = switch (status) {
        PermissionStatus.granted || PermissionStatus.limited => PermissionStatusState.granted,
        PermissionStatus.permanentlyDenied => PermissionStatusState.permanentlyDenied,
        _ => PermissionStatusState.denied,
      };
    } catch (e) {
      debugPrint('[PERMISSION] check failed: $e');
      state = PermissionStatusState.denied;
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isAndroid) return true;
    await [Permission.bluetoothConnect, Permission.notification].request();
    await checkPermissions();
    return state == PermissionStatusState.granted;
  }

  Future<bool> get notificationsGranted async => !_isAndroid || await Permission.notification.isGranted;

  Future<void> requestNotifications() async {
    if (_isAndroid) await Permission.notification.request();
  }
}

final permissionProvider = NotifierProvider<PermissionNotifier, PermissionStatusState>(PermissionNotifier.new);
