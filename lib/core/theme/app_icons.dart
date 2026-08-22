import 'package:lucide_icons/lucide_icons.dart';

/// Lucide icons aligned with mock-frontend (`lucide-react`) for a consistent ed-tech look.
abstract final class AppIcons {
  static const dashboard = LucideIcons.layoutDashboard;
  static const dashboardSelected = LucideIcons.layoutDashboard;

  static const practice = LucideIcons.bookOpen;
  static const practiceSelected = LucideIcons.bookOpen;

  static const leaderboard = LucideIcons.trophy;
  static const leaderboardSelected = LucideIcons.trophy;

  static const results = LucideIcons.barChart3;
  static const resultsSelected = LucideIcons.barChart3;

  static const menu = LucideIcons.menu;
  static const community = LucideIcons.messagesSquare;
  static const notifications = LucideIcons.bell;
  static const unlock = LucideIcons.sparkles;
  static const profile = LucideIcons.user;
  static const logout = LucideIcons.logOut;
  static const streak = LucideIcons.flame;
  /// Use [MockLongArrowIcon] with [MockLongArrowDirection.left] for navigation back.
  static const backSize = 22.0;
  static const forwardSize = 18.0;
  static const navSize = 20.0;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
}
