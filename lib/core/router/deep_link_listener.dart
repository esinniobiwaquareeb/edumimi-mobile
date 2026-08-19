import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/router/app_router.dart';
import 'package:mock_mobile/core/router/deep_link_resolver.dart';

class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDeepLinks());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleLatestLink());
    }
  }

  Future<void> _initializeDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }
  }

  Future<void> _handleLatestLink() async {
    final latestUri = await _appLinks.getLatestLink();
    if (latestUri != null) {
      _handleUri(latestUri);
    }
  }

  void _handleUri(Uri uri) {
    final route = DeepLinkResolver.resolveRoute(uri);
    if (route == null || route == _lastHandledRoute) {
      return;
    }

    _lastHandledRoute = route;
    ref.read(routerProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
