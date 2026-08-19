import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
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
      await ref.read(authControllerProvider.notifier).signup(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/dashboard');
      }
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
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Start free practice in minutes.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                MockTextField(
                  label: 'Full name',
                  controller: _nameController,
                  validator: (value) => value != null && value.trim().length >= 2 ? null : 'Enter your name',
                ),
                const SizedBox(height: 12),
                MockTextField(
                  label: 'Email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                MockTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 8 ? null : 'Use at least 8 characters',
                ),
                const SizedBox(height: 20),
                MockPrimaryButton(label: 'Sign up free', isLoading: _isLoading, onPressed: _submit),
                const SizedBox(height: 12),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Log in')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
