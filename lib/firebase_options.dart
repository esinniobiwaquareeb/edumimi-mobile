import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:mock_mobile/core/config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'placeholder-api-key'),
      appId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:000000000000:android:0000000000000000000000'),
      messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
      projectId: AppConfig.firebaseProjectId.isNotEmpty
          ? AppConfig.firebaseProjectId
          : 'mock-edumimi-dev',
    );
  }

  static bool get isConfigured => AppConfig.isFirebaseConfigured && !kIsWeb;
}
