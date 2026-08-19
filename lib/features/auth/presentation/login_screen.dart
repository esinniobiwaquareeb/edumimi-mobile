import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorMessage = _error ?? authState.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.page),
                    const MockBrandLockup(),
                    const SizedBox(height: AppSpacing.page),
                    Text('Sign in', style: context.pageTitle),
                    const SizedBox(height: AppSpacing.item),
                    Text('Continue your practice and saved scores.', style: context.pageSubtitle),
                    const SizedBox(height: AppSpacing.page),
                    MockAuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (errorMessage != null) ...[
                            MockInlineNotice.error(message: errorMessage),
                            const SizedBox(height: AppSpacing.section),
                          ],
                          MockTextField(
                            label: 'Email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                          ),
                          const SizedBox(height: AppSpacing.section),
                          MockTextField(
                            label: 'Password',
                            controller: _passwordController,
                            obscurable: true,
                            validator: (value) => value != null && value.length >= 6 ? null : 'Enter your password',
                          ),
                          const SizedBox(height: AppSpacing.page),
                          MockPrimaryButton(label: 'Log in', isLoading: _isLoading, onPressed: _submit),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('No account yet? Sign up free'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
