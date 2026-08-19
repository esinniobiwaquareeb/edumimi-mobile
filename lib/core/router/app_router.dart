import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/features/auth/presentation/login_screen.dart';
import 'package:mock_mobile/features/auth/presentation/signup_screen.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/community/presentation/community_screen.dart';
import 'package:mock_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_detail_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_session_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exams_screen.dart';
import 'package:mock_mobile/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:mock_mobile/features/payments/presentation/packages_screen.dart';
import 'package:mock_mobile/features/payments/presentation/payment_checkout_screen.dart';
import 'package:mock_mobile/features/payments/presentation/payment_verify_screen.dart';
import 'package:mock_mobile/features/profile/presentation/profile_screen.dart';
import 'package:mock_mobile/features/results/presentation/results_screen.dart';
import 'package:mock_mobile/features/shell/presentation/main_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isBootstrapping = authState.status == AuthStatus.unknown;
      if (isBootstrapping) {
        return null;
      }

      final loggedIn = authState.isAuthenticated;
      final authRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn && !authRoute) {
        return '/login';
      }
      if (loggedIn && authRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/exams', builder: (context, state) => const ExamsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/leaderboard', builder: (context, state) => const LeaderboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/results', builder: (context, state) => const ResultsScreen()),
            ],
          ),
        ],
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/packages', builder: (context, state) => const PackagesScreen()),
      GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
      GoRoute(
        path: '/payments/checkout',
        builder: (context, state) => PaymentCheckoutScreen(
          authorizationUrl: state.uri.queryParameters['url'] ?? '',
          paymentReference: state.uri.queryParameters['reference'] ?? '',
        ),
      ),
      GoRoute(
        path: '/payments/verify',
        builder: (context, state) => PaymentVerifyScreen(
          reference: state.uri.queryParameters['reference'] ?? '',
        ),
      ),
      GoRoute(
        path: '/exams/:slug',
        builder: (context, state) => ExamDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/exams/:slug/take',
        builder: (context, state) => ExamSessionScreen(
          slug: state.pathParameters['slug']!,
          attemptId: state.uri.queryParameters['attemptId'],
        ),
      ),
    ],
  );
});
