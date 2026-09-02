import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/notifications/data/notifications_repository.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
import 'package:mock_mobile/firebase_options.dart';

const _iosPushChannel = MethodChannel('com.edumimi.mock/push');

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService(this._repository, {this.onNotificationReceived});

  final PaymentRepository _repository;
  final void Function()? onNotificationReceived;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  var _localNotificationsReady = false;
  var _firebaseInitialized = false;
  var _listenersAttached = false;
  String? _currentToken;
  GoRouter? _router;

  bool get isFirebaseAvailable => DefaultFirebaseOptions.isConfigured;

  Future<bool> initialize(GoRouter router) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return false;
    }

    try {
      _router = router;
      if (!_firebaseInitialized) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        _firebaseInitialized = true;
      }

      await _ensureLocalNotifications();

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      if (Platform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
        await _registerForRemoteNotificationsOnIos();
      }

      final token = await _resolveFcmToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      await _registerToken(token);
      _attachMessagingListeners(router);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return;
    }

    try {
      if (!_firebaseInitialized) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _firebaseInitialized = true;
      }

      final token = _currentToken ?? await _resolveFcmToken();
      if (token != null && token.isNotEmpty) {
        await _repository.unregisterFcmToken(token);
        _currentToken = null;
      }

      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      _currentToken = null;
    }
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
      body:
          'You have an active practice streak — complete one mock today to extend it.',
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

  Future<void> _registerForRemoteNotificationsOnIos() async {
    try {
      await _iosPushChannel.invokeMethod<void>(
        'registerForRemoteNotifications',
      );
    } catch (_) {
      // Native channel unavailable — Firebase proxy may still register later.
    }
  }

  Future<String?> _resolveFcmToken() async {
    if (Platform.isIOS) {
      await _waitForApnsToken();
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } on FirebaseException catch (error) {
        if (!_isApnsTokenPending(error)) {
          return null;
        }
      } catch (_) {
        return null;
      }

      await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }

    return null;
  }

  Future<void> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          return;
        }
      } on FirebaseException catch (error) {
        if (!_isApnsTokenPending(error)) {
          return;
        }
      } catch (_) {
        return;
      }

      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }

  bool _isApnsTokenPending(FirebaseException error) {
    return error.code == 'apns-token-not-set';
  }

  void _attachMessagingListeners(GoRouter router) {
    if (_listenersAttached) {
      return;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_registerTokenSafely(token));
    });
    FirebaseMessaging.onMessage.listen((message) {
      onNotificationReceived?.call();
      unawaited(_showForegroundNotification(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationReceived?.call();
      _handleNavigation(router, message.data);
    });

    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
        if (initialMessage != null) {
          onNotificationReceived?.call();
          _handleNavigation(router, initialMessage.data);
        }
      }),
    );

    _listenersAttached = true;
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    await _repository.registerFcmToken(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  Future<void> _registerTokenSafely(String token) async {
    try {
      await _registerToken(token);
    } catch (_) {
      // Ignore background refresh failures (e.g. logged out).
    }
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
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (_isAllowedRoute(route)) {
          _router?.go(route!);
        }
      },
    );
    _localNotificationsReady = true;
  }

  Future<bool> _requestLocalPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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
      payload: message.data['route']?.toString(),
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
    final route = _resolveInternalRoute(data);
    router.go(route ?? '/dashboard');
  }

  String? _resolveInternalRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (_isAllowedRoute(route)) {
      return route;
    }

    final url = Uri.tryParse(data['url']?.toString() ?? '');
    if (url != null && _isAllowedRoute(url.path)) {
      return url.hasQuery ? '${url.path}?${url.query}' : url.path;
    }

    return null;
  }

  bool _isAllowedRoute(String? route) {
    if (route == null || !route.startsWith('/') || route.startsWith('//')) {
      return false;
    }
    const allowedPrefixes = [
      '/dashboard',
      '/exams',
      '/packages',
      '/notifications',
      '/community',
      '/profile',
      '/results',
    ];
    return allowedPrefixes.any(
      (prefix) => route == prefix || route.startsWith('$prefix/'),
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    ref.watch(paymentRepositoryProvider),
    onNotificationReceived: () {
      invalidateNotificationsFromRef(ref);
      invalidateUnreadSummaryFromRef(ref);
    },
  );
});
