import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/offline/offline_sync_listener.dart';
import 'package:mock_mobile/core/router/app_router.dart';
import 'package:mock_mobile/core/router/deep_link_listener.dart';
import 'package:mock_mobile/core/theme/app_theme.dart';
import 'package:mock_mobile/core/theme/theme_provider.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/notifications/presentation/app_icon_badge_listener.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';
import 'package:mock_mobile/firebase_options.dart';

class MockMobileApp extends ConsumerStatefulWidget {
  const MockMobileApp({super.key});

  @override
  ConsumerState<MockMobileApp> createState() => _MockMobileAppState();
}

class _MockMobileAppState extends ConsumerState<MockMobileApp> {
  var _pushBootstrapAttempted = false;

  Future<void> _bootstrapPushIfNeeded() async {
    if (_pushBootstrapAttempted || !DefaultFirebaseOptions.isConfigured) {
      return;
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.isInitializing) {
      return;
    }

    _pushBootstrapAttempted = true;
    final router = ref.read(routerProvider);
    try {
      await ref.read(pushNotificationServiceProvider).initialize(router);
    } catch (_) {
      _pushBootstrapAttempted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && !next.isInitializing) {
        _bootstrapPushIfNeeded();
        return;
      }
      if (!next.isAuthenticated) {
        _pushBootstrapAttempted = false;
      }
    });

    final auth = ref.watch(authControllerProvider);
    if (auth.isAuthenticated && !auth.isInitializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bootstrapPushIfNeeded();
      });
    }

    return AppIconBadgeListener(
      child: DeepLinkListener(
        child: OfflineSyncListener(
          child: MaterialApp.router(
            title: AppConfig.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
