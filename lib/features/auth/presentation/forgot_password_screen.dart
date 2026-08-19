import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  var _isLoading = false;
  var _isSuccess = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      setState(() => _isSuccess = true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MockDetailAppBar(
        title: 'Reset password',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/login');
          }
        },
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset your password', style: context.pageTitle),
                const SizedBox(height: AppSpacing.item),
                Text('Enter your email to get a reset link.', style: context.pageSubtitle),
                const SizedBox(height: AppSpacing.page),
                if (_isSuccess)
                  MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const MockInlineNotice.success(
                          message: 'Reset instructions have been sent if your account exists.',
                        ),
                        const SizedBox(height: AppSpacing.section),
                        MockPrimaryButton(label: 'Back to sign in', onPressed: () => context.go('/login')),
                      ],
                    ),
                  )
                else
                  MockAuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          MockInlineNotice.error(message: _error!),
                          const SizedBox(height: AppSpacing.section),
                        ],
                        MockTextField(
                          label: 'Email address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.page),
                        MockPrimaryButton(
                          label: _isLoading ? 'Sending link…' : 'Send reset link',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        TextButton(onPressed: () => context.go('/login'), child: const Text('Back to sign in')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
