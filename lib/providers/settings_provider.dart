import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_preferences.dart';
import 'data_providers.dart';

/// Loads preferences from the database, persists every change, and mirrors hearing settings to
/// the native engine (which needs them for background alerts and the live notification).
class SettingsNotifier extends Notifier<AppPreferences> {
  bool _loaded = false;

  @override
  AppPreferences build() {
    unawaited(_load());
    return const AppPreferences();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    try {
      final stored = await db.getAllSettings();
      if (!ref.mounted) return;
      state = AppPreferences.fromStorage(stored);
      _loaded = true;
      await ref.read(trackingPlatformProvider).updateNativeSettings(state.toNative());
    } catch (e) {
      debugPrint('[SETTINGS] load failed: $e');
    }
  }

  Future<void> update(AppPreferences Function(AppPreferences current) change) async {
    final next = change(state);
    state = next;
    final db = ref.read(databaseProvider);
    for (final entry in next.toStorage().entries) {
      await db.setSetting(entry.key, entry.value);
    }
    await ref.read(trackingPlatformProvider).updateNativeSettings(next.toNative());
  }

  bool get isLoaded => _loaded;

  void setThemeMode(ThemeMode mode) => update((p) => p.copyWith(themeMode: mode));
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppPreferences>(SettingsNotifier.new);

/// Read-only view of preferences for widgets and derived providers.
final preferencesProvider = Provider<AppPreferences>((ref) => ref.watch(settingsProvider));

final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(settingsProvider.select((p) => p.themeMode)));
