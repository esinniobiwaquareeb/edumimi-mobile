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
  var _initialized = false;
  String? _currentToken;

  Future<bool> initialize(GoRouter router) async {
    if (!AppConfig.isFirebaseConfigured) {
      return false;
    }

    if (!_initialized) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _configureLocalNotifications();
      _initialized = true;
    }

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
    await FirebaseMessaging.instance.deleteToken();
  }

  Future<bool> get isEnabled async {
    if (!AppConfig.isFirebaseConfigured) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    return token != null && token.isNotEmpty && _currentToken != null;
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    await _repository.registerFcmToken(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  Future<void> _configureLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

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
