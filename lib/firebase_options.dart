import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    if (Platform.isIOS) {
      return ios;
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJHuEpHBlicSPkXnTYrR8GsL5uTF7dnp0',
    appId: '1:345341033333:android:4564ac6f0815bc9e52313c',
    messagingSenderId: '345341033333',
    projectId: 'edumimi-mock',
    storageBucket: 'edumimi-mock.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-flofqni9Ls09XHLUbulNl5jjBQp7_oY',
    appId: '1:345341033333:ios:379d8285ede331f952313c',
    messagingSenderId: '345341033333',
    projectId: 'edumimi-mock',
    storageBucket: 'edumimi-mock.firebasestorage.app',
    iosBundleId: 'com.edumimi.mock',
  );

  static bool get isConfigured => !kIsWeb;
}
