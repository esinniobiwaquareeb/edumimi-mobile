import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mock_mobile/core/offline/offline_storage.dart';

final appPrefsStorageProvider = Provider<AppPrefsStorage>((ref) => AppPrefsStorage());

class AppPrefsStorage {
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _themeModeKey = 'theme_mode';

  Box<dynamic> get _box => Hive.box<dynamic>(OfflineStorage.appPrefsBoxName);

  Future<bool> hasSeenOnboarding() async {
    return _box.get(_onboardingSeenKey, defaultValue: false) == true;
  }

  Future<void> setOnboardingSeen() async {
    await _box.put(_onboardingSeenKey, true);
  }

  Future<AppThemeMode> readThemeMode() async {
    final raw = _box.get(_themeModeKey)?.toString();
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _box.put(_themeModeKey, mode.name);
  }
}

enum AppThemeMode { light, dark, system }
