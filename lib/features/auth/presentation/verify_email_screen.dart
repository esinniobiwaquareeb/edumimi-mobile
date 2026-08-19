import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/data/auth_repository.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  var _status = _VerifyStatus.loading;
  String _message = 'Verifying your email…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _status = _VerifyStatus.error;
        _message = 'This verification link is invalid or incomplete.';
      });
      return;
    }
    try {
      final session = await ref.read(authRepositoryProvider).verifyEmail(token: token);
      await ref.read(authControllerProvider.notifier).applyVerifiedSession(session);
      setState(() {
        _status = _VerifyStatus.success;
        _message = 'Email verified. Continue to choose your interests.';
      });
    } on ApiException catch (error) {
      setState(() {
        _status = _VerifyStatus.error;
        _message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MockDetailAppBar(
        title: 'Verify email',
        onBack: () => context.go('/login'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == _VerifyStatus.loading) ...[
                const MockLoadingView(message: 'Verifying…'),
                const SizedBox(height: AppSpacing.section),
                Text(_message, style: context.bodySecondary, textAlign: TextAlign.center),
              ],
              if (_status == _VerifyStatus.success) ...[
                const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.section),
                Text('Email verified', style: context.pageTitle, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.item),
                Text(_message, style: context.bodySecondary, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.page),
                MockPrimaryButton(
                  label: 'Continue',
                  onPressed: () => context.go('/onboarding/interests'),
                ),
              ],
              if (_status == _VerifyStatus.error) ...[
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.section),
                Text('Verification failed', style: context.pageTitle, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.item),
                Text(_message, style: context.bodySecondary, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.page),
                MockSecondaryButton(label: 'Back to sign in', onPressed: () => context.go('/login')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _VerifyStatus { loading, success, error }
