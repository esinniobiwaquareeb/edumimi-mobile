import 'package:app_badge_plus/app_badge_plus.dart';

/// Keeps the launcher/home-screen icon badge in sync with unread counts.
class AppIconBadgeService {
  AppIconBadgeService._();

  static int? _lastAppliedCount;

  static Future<void> sync(int count) async {
    final normalized = count <= 0 ? 0 : count.clamp(1, 999);
    if (_lastAppliedCount == normalized) {
      return;
    }

    try {
      if (normalized == 0) {
        await AppBadgePlus.updateBadge(0);
        _lastAppliedCount = 0;
        return;
      }

      final supported = await AppBadgePlus.isSupported();
      if (!supported) {
        return;
      }

      await AppBadgePlus.updateBadge(normalized);
      _lastAppliedCount = normalized;
    } catch (_) {
      // Badge APIs can fail on unsupported launchers — ignore silently.
    }
  }

  static Future<void> clear() => sync(0);
}
