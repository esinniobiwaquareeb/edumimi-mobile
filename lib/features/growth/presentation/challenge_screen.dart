import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  var _isStarting = false;

  Future<void> _acceptChallenge() async {
    final challenge = await ref.read(publicChallengeProvider(widget.token).future);
    final loggedIn = ref.read(authControllerProvider).isAuthenticated;
    if (!loggedIn) {
      if (mounted) context.go('/login?redirect=${Uri.encodeComponent('/challenge/${widget.token}')}');
      return;
    }
    setState(() => _isStarting = true);
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await ref.read(mockPortalRepositoryProvider).startExam(
            challenge.exam.slug,
            sessionId: sessionId,
            challengeToken: widget.token,
          );
      if (mounted) {
        context.push(
          '/exams/${challenge.exam.slug}/take?attemptId=${Uri.encodeComponent(response.attemptId)}&sessionId=${Uri.encodeComponent(sessionId)}',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        MockToast.error(context, error.message);
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(publicChallengeProvider(widget.token));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Friend challenge'),
      body: challengeAsync.when(
        loading: () => const MockLoadingView(message: 'Loading challenge…'),
        error: (_, __) => const MockEmptyState(
          title: 'Challenge not found',
          message: 'This link may have expired or the score was removed.',
        ),
        data: (challenge) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            MockCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${challenge.challengerName} scored ${challenge.percentScore.round()}%',
                    style: context.pageTitle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: AppSpacing.item),
                  Text(
                    'On ${challenge.exam.title}${challenge.exam.subjectName != null ? ' · ${challenge.exam.subjectName}' : ''}. Take the same paper and see if you can beat it.',
                    style: context.bodySecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.page),
            MockPrimaryButton(
              label: _isStarting ? 'Starting…' : 'Take same exam',
              isLoading: _isStarting,
              onPressed: _acceptChallenge,
            ),
          ],
        ),
      ),
    );
  }
}
