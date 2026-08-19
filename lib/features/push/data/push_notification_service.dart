import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService(this._repository);

  final PaymentRepository _repository;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  var _localNotificationsReady = false;
  var _firebaseInitialized = false;
  String? _currentToken;

  bool get isFirebaseAvailable => AppConfig.isFirebaseConfigured;

  Future<bool> initialize(GoRouter router) async {
    if (!AppConfig.isFirebaseConfigured) {
      return false;
    }

    if (!_firebaseInitialized) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseInitialized = true;
    }

    await _ensureLocalNotifications();

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    await _registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(router, message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(router, initialMessage.data);
    }

    return true;
  }

  Future<void> disable() async {
    if (_currentToken != null) {
      await _repository.unregisterFcmToken(_currentToken!);
      _currentToken = null;
    }
    if (AppConfig.isFirebaseConfigured && _firebaseInitialized) {
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  Future<bool> get isEnabled async {
    if (!AppConfig.isFirebaseConfigured) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    return token != null && token.isNotEmpty && _currentToken != null;
  }

  /// Preview a streak reminder using local notifications only (no FCM required).
  Future<bool> previewLocalStreakReminder() async {
    await _ensureLocalNotifications();
    final granted = await _requestLocalPermission();
    if (!granted) {
      return false;
    }

    await _localNotifications.show(
      id: 9001,
      title: 'Keep your streak alive!',
      body: 'You have an active practice streak — complete one mock today to extend it.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mock_streak_reminders',
          'Practice reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return true;
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    await _repository.registerFcmToken(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  Future<void> _ensureLocalNotifications() async {
    if (_localNotificationsReady) {
      return;
    }

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _localNotificationsReady = true;
  }

  Future<bool> _requestLocalPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _ensureLocalNotifications();
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mock_streak_reminders',
          'Practice reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleNavigation(GoRouter router, Map<String, dynamic> data) {
    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      router.go('/dashboard');
      return;
    }
    if (url.contains('/dashboard')) {
      router.go('/dashboard');
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(paymentRepositoryProvider));
});
