import 'package:flutter/material.dart' show ThemeMode;

import '../logic/exposure_math.dart';

/// User preferences. Stored in the app database; the hearing-related values are mirrored to the
/// native engine so background alerts use exactly the same calibration as the UI.
class AppPreferences {
  final ThemeMode themeMode;

  /// Estimated output of the user's headphones at 100% volume, dB(A).
  final double maxOutputDb;

  /// Level that triggers the sustained-loudness alert, dB(A).
  final double loudThresholdDb;
  final bool alertsEnabled;

  /// Continuous minutes before a break reminder (0 = off).
  final int breakReminderMinutes;

  /// Daily listening goal in minutes (0 = off).
  final int dailyLimitMinutes;

  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.maxOutputDb = ExposureMath.defaultMaxOutputDb,
    this.loudThresholdDb = 90,
    this.alertsEnabled = true,
    this.breakReminderMinutes = 60,
    this.dailyLimitMinutes = 180,
  });

  AppPreferences copyWith({
    ThemeMode? themeMode,
    double? maxOutputDb,
    double? loudThresholdDb,
    bool? alertsEnabled,
    int? breakReminderMinutes,
    int? dailyLimitMinutes,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      maxOutputDb: maxOutputDb ?? this.maxOutputDb,
      loudThresholdDb: loudThresholdDb ?? this.loudThresholdDb,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      breakReminderMinutes: breakReminderMinutes ?? this.breakReminderMinutes,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    );
  }

  Map<String, String> toStorage() => {
        'themeMode': themeMode.name,
        'maxOutputDb': maxOutputDb.toString(),
        'loudThresholdDb': loudThresholdDb.toString(),
        'alertsEnabled': alertsEnabled.toString(),
        'breakReminderMinutes': breakReminderMinutes.toString(),
        'dailyLimitMinutes': dailyLimitMinutes.toString(),
      };

  factory AppPreferences.fromStorage(Map<String, String> s) {
    const d = AppPreferences();
    return AppPreferences(
      themeMode: ThemeMode.values.asNameMap()[s['themeMode']] ?? d.themeMode,
      maxOutputDb: double.tryParse(s['maxOutputDb'] ?? '') ?? d.maxOutputDb,
      loudThresholdDb: double.tryParse(s['loudThresholdDb'] ?? '') ?? d.loudThresholdDb,
      alertsEnabled: bool.tryParse(s['alertsEnabled'] ?? '') ?? d.alertsEnabled,
      breakReminderMinutes: int.tryParse(s['breakReminderMinutes'] ?? '') ?? d.breakReminderMinutes,
      dailyLimitMinutes: int.tryParse(s['dailyLimitMinutes'] ?? '') ?? d.dailyLimitMinutes,
    );
  }

  /// The subset the native engine needs.
  Map<String, Object?> toNative() => {
        'maxOutputDb': maxOutputDb,
        'loudThresholdDb': loudThresholdDb,
        'alertsEnabled': alertsEnabled,
        'breakReminderMinutes': breakReminderMinutes,
        'dailyLimitMinutes': dailyLimitMinutes,
      };
}
