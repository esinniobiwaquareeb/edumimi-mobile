import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:mock_mobile/features/auth/presentation/login_screen.dart';
import 'package:mock_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:mock_mobile/features/auth/presentation/signup_screen.dart';
import 'package:mock_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/community/presentation/community_screen.dart';
import 'package:mock_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_attempts_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_catalog_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_detail_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_session_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exam_types_screen.dart';
import 'package:mock_mobile/features/exams/presentation/exams_screen.dart';
import 'package:mock_mobile/features/growth/presentation/challenge_screen.dart';
import 'package:mock_mobile/features/growth/presentation/jamb_syllabus_screen.dart';
import 'package:mock_mobile/features/growth/presentation/parent_view_screen.dart';
import 'package:mock_mobile/features/growth/presentation/post_utme_packs_screen.dart';
import 'package:mock_mobile/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:mock_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:mock_mobile/features/onboarding/presentation/interest_onboarding_screen.dart';
import 'package:mock_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mock_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:mock_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:mock_mobile/features/payments/presentation/packages_screen.dart';
import 'package:mock_mobile/features/payments/presentation/payment_checkout_screen.dart';
import 'package:mock_mobile/features/payments/presentation/payment_verify_screen.dart';
import 'package:mock_mobile/features/profile/presentation/profile_screen.dart';
import 'package:mock_mobile/features/results/presentation/result_detail_screen.dart';
import 'package:mock_mobile/features/results/presentation/results_screen.dart';
import 'package:mock_mobile/features/shell/presentation/main_shell_screen.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool _isPublicRoute(String location) {
    return location.startsWith('/forgot-password') ||
        location.startsWith('/reset-password') ||
        location.startsWith('/verify-email') ||
        location.startsWith('/challenge/') ||
        location.startsWith('/parent/');
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final onboardingState = _ref.read(onboardingControllerProvider);
    final location = state.matchedLocation;
    final isSplash = location == '/splash';
    final isOnboarding = location == '/onboarding';
    final isInterestOnboarding = location == '/onboarding/interests';
    final isAuthRoute = location == '/login' || location == '/signup';
    final isBootstrapping = authState.isInitializing || onboardingState.isLoading;

    if (isBootstrapping) {
      return isSplash ? null : '/splash';
    }

    if (isSplash) {
      if (!onboardingState.hasSeenOnboarding) {
        return '/onboarding';
      }
      if (authState.isAuthenticated) {
        final user = authState.user;
        if (user?.mockProfile?.onboardingCompleted != true) {
          return '/onboarding/interests';
        }
        return '/dashboard';
      }
      return '/login';
    }

    if (!onboardingState.hasSeenOnboarding && !isOnboarding) {
      return '/onboarding';
    }

    if (onboardingState.hasSeenOnboarding && isOnboarding) {
      if (authState.isAuthenticated) {
        if (authState.user?.mockProfile?.onboardingCompleted != true) {
          return '/onboarding/interests';
        }
        return '/dashboard';
      }
      return '/login';
    }

    final loggedIn = authState.isAuthenticated;
    if (_isPublicRoute(location)) {
      return null;
    }

    if (!loggedIn && !isAuthRoute && !isOnboarding && !isInterestOnboarding) {
      return '/login';
    }

    if (loggedIn && isAuthRoute) {
      final redirect = state.uri.queryParameters['redirect'];
      if (redirect != null && redirect.startsWith('/') && !redirect.startsWith('//')) {
        return redirect;
      }
      if (authState.user?.mockProfile?.onboardingCompleted != true) {
        return '/onboarding/interests';
      }
      return '/dashboard';
    }

    if (loggedIn && isInterestOnboarding && authState.user?.mockProfile?.onboardingCompleted == true) {
      return '/dashboard';
    }

    if (loggedIn && !isInterestOnboarding && authState.user?.mockProfile?.onboardingCompleted != true) {
      final allowed = isAuthRoute || location == '/profile';
      if (!allowed) {
        return '/onboarding/interests';
      }
    }

    return null;
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: const String.fromEnvironment(
      'MOCK_INITIAL_ROUTE',
      defaultValue: '/splash',
    ),
    refreshListenable: refreshNotifier,
    redirect: refreshNotifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/onboarding/interests', builder: (context, state) => const InterestOnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupScreen(
          initialReferralCode: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => VerifyEmailScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/challenge/:token',
        builder: (context, state) => ChallengeScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(
        path: '/parent/:token',
        builder: (context, state) => ParentViewScreen(token: state.pathParameters['token']!),
      ),
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
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/packages', builder: (context, state) => const PackagesScreen()),
      GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
      GoRoute(path: '/exam-types', builder: (context, state) => const ExamTypesScreen()),
      GoRoute(path: '/jamb/syllabus', builder: (context, state) => const JambSyllabusScreen()),
      GoRoute(path: '/post-utme', builder: (context, state) => const PostUtmePacksScreen()),
      GoRoute(
        path: '/post-utme/:slug',
        builder: (context, state) => PostUtmePackDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/exam-types/:slug',
        builder: (context, state) => ExamCatalogScreen(examTypeSlug: state.pathParameters['slug']!),
      ),
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
        path: '/results/:attemptId',
        builder: (context, state) => ResultDetailScreen(attemptId: state.pathParameters['attemptId']!),
      ),
      GoRoute(
        path: '/exams/:slug/attempts',
        builder: (context, state) => ExamAttemptsScreen(slug: state.pathParameters['slug']!),
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
          sessionId: state.uri.queryParameters['sessionId'],
        ),
      ),
    ],
  );
});
