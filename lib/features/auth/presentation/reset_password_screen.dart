import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/data/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _isLoading = false;
  var _isSuccess = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'This reset link is invalid or incomplete.');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters long.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: token,
            newPassword: _passwordController.text,
          );
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
        title: 'New password',
        onBack: () => context.go('/login'),
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
                const MockBrandLogo(compact: true),
                const SizedBox(height: AppSpacing.page),
                Text('Choose a new password', style: context.pageTitle),
                const SizedBox(height: AppSpacing.page),
                if (_isSuccess)
                  MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const MockInlineNotice.success(message: 'Your password has been reset successfully.'),
                        const SizedBox(height: AppSpacing.section),
                        MockPrimaryButton(label: 'Sign in now', onPressed: () => context.go('/login')),
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
                        MockTextField(label: 'New password', controller: _passwordController, obscurable: true),
                        const SizedBox(height: AppSpacing.section),
                        MockTextField(label: 'Confirm password', controller: _confirmController, obscurable: true),
                        const SizedBox(height: AppSpacing.page),
                        MockPrimaryButton(
                          label: _isLoading ? 'Updating password…' : 'Reset password',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
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
