import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/storage/app_prefs_storage.dart';

class ThemeController extends Notifier<ThemeMode> {
  late AppPrefsStorage _storage;

  @override
  ThemeMode build() {
    _storage = ref.read(appPrefsStorageProvider);
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final saved = await _storage.readThemeMode();
    state = _toThemeMode(saved);
  }

  Future<void> setMode(AppThemeMode mode) async {
    await _storage.saveThemeMode(mode);
    state = _toThemeMode(mode);
  }

  ThemeMode _toThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
