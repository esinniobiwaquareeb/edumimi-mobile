import 'package:mock_mobile/core/config/app_config.dart';

/// Maps incoming custom-scheme and HTTPS deep links to go_router locations.
class DeepLinkResolver {
  const DeepLinkResolver._();

  static String? resolveRoute(Uri uri) {
    final path = _normalizePath(uri);
    if (path == null) {
      return null;
    }
    return _buildRoute(path, uri.queryParameters);
  }

  static String? _normalizePath(Uri uri) {
    if (uri.scheme == AppConfig.deepLinkScheme) {
      if (uri.host != 'app') {
        return null;
      }
      return _ensureLeadingSlash(uri.path);
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final webHost = Uri.parse(AppConfig.webShareOrigin).host;
      if (uri.host != webHost) {
        return null;
      }

      final path = _ensureLeadingSlash(uri.path);
      return switch (path) {
        '/auth/verify-email' => '/verify-email',
        '/auth/reset-password' => '/reset-password',
        _ => path,
      };
    }

    return null;
  }

  static String? _buildRoute(String path, Map<String, String> queryParameters) {
    const queryRoutes = {
      '/verify-email',
      '/reset-password',
      '/payments/verify',
    };

    if (queryRoutes.contains(path)) {
      if (queryParameters.isEmpty) {
        return path;
      }
      return Uri(path: path, queryParameters: queryParameters).toString();
    }

    final challengeMatch = RegExp(r'^/challenge/([^/]+)$').firstMatch(path);
    if (challengeMatch != null) {
      final token = Uri.decodeComponent(challengeMatch.group(1)!);
      return '/challenge/${Uri.encodeComponent(token)}';
    }

    final parentMatch = RegExp(r'^/parent/([^/]+)$').firstMatch(path);
    if (parentMatch != null) {
      final token = Uri.decodeComponent(parentMatch.group(1)!);
      return '/parent/${Uri.encodeComponent(token)}';
    }

    return null;
  }

  static String _ensureLeadingSlash(String path) {
    if (path.isEmpty) {
      return '/';
    }
    return path.startsWith('/') ? path : '/$path';
  }
}
