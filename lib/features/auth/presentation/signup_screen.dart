import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.initialReferralCode});

  final String? initialReferralCode;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  var _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final referral = widget.initialReferralCode?.trim();
    if (referral != null && referral.isNotEmpty) {
      _referralController.text = referral.toUpperCase();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
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
      await ref.read(authControllerProvider.notifier).signup(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            referralCode: _referralController.text.trim().isEmpty ? null : _referralController.text,
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
    return Scaffold(
      appBar: MockDetailAppBar(
        title: 'Create account',
        onBack: () => context.go('/login'),
      ),
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
                    const MockBrandLogo(compact: true),
                    const SizedBox(height: AppSpacing.page),
                    Text('Start free practice in minutes.', style: context.pageSubtitle),
                    const SizedBox(height: AppSpacing.page),
                    MockAuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            MockInlineNotice.error(message: _error!),
                            const SizedBox(height: AppSpacing.section),
                          ],
                          MockTextField(
                            label: 'Full name',
                            controller: _nameController,
                            validator: (value) => value != null && value.trim().length >= 2 ? null : 'Enter your name',
                          ),
                          const SizedBox(height: AppSpacing.section),
                          MockTextField(
                            label: 'Email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                          ),
                          const SizedBox(height: AppSpacing.section),
                          MockTextField(
                            label: 'Referral code (optional)',
                            controller: _referralController,
                          ),
                          const SizedBox(height: AppSpacing.section),
                      MockTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscurable: true,
                        validator: (value) => value != null && value.length >= 8 ? null : 'Use at least 8 characters',
                      ),
                          const SizedBox(height: AppSpacing.page),
                          MockPrimaryButton(label: 'Create account', isLoading: _isLoading, onPressed: _submit),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Log in'),
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
