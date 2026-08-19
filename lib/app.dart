import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/offline/offline_sync_listener.dart';
import 'package:mock_mobile/core/router/app_router.dart';
import 'package:mock_mobile/core/theme/app_theme.dart';

class MockMobileApp extends ConsumerWidget {
  const MockMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return OfflineSyncListener(
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
