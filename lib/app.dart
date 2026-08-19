import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/offline/offline_sync_listener.dart';
import 'package:mock_mobile/core/router/app_router.dart';
import 'package:mock_mobile/core/router/deep_link_listener.dart';
import 'package:mock_mobile/core/theme/app_theme.dart';
import 'package:mock_mobile/core/theme/theme_provider.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';

class MockMobileApp extends ConsumerStatefulWidget {
  const MockMobileApp({super.key});

  @override
  ConsumerState<MockMobileApp> createState() => _MockMobileAppState();
}

class _MockMobileAppState extends ConsumerState<MockMobileApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!AppConfig.isFirebaseConfigured) {
        return;
      }
      final router = ref.read(routerProvider);
      await ref.read(pushNotificationServiceProvider).initialize(router);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return DeepLinkListener(
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
    );
  }
}
