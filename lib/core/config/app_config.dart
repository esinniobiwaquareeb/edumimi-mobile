import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const _apiUrlFromDefine = String.fromEnvironment('MOCK_API_URL');
  static const _defaultProductionApiUrl = 'https://api.edumimi.com';
  static const _defaultDevPort = 3000;

  /// API origin without trailing slash.
  ///
  /// Priority:
  /// 1. `--dart-define=MOCK_API_URL=...` at build time
  /// 2. Release/profile without define → production API
  /// 3. Debug without define → platform dev host (Android emulator uses 10.0.2.2)
  static String get apiBaseUrl {
    if (_apiUrlFromDefine.isNotEmpty) {
      return _trimTrailingSlash(_apiUrlFromDefine);
    }

    if (kReleaseMode || kProfileMode) {
      return _defaultProductionApiUrl;
    }

    return _trimTrailingSlash(_devFallbackHost());
  }

  static String _devFallbackHost() {
    if (kIsWeb) {
      return 'http://localhost:$_defaultDevPort';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_defaultDevPort';
    }
    return 'http://127.0.0.1:$_defaultDevPort';
  }

  static String _trimTrailingSlash(String url) {
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  static const apiPrefix = '/mock-portal';
  static const appName = 'Edumimi Mock';
  static const deepLinkScheme = 'mockedumimi';
  static const webShareOrigin = String.fromEnvironment(
    'MOCK_WEB_URL',
    defaultValue: 'https://mock.edumimi.com',
  );

  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'edumimi-mock',
  );

  static bool get isFirebaseConfigured => firebaseProjectId.isNotEmpty;
}
