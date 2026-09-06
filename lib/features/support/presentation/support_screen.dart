import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _supportUrl = 'https://mock.edumimi.com/support';
  static const _privacyUrl = 'https://mock.edumimi.com/privacy';
  static const _termsUrl = 'https://mock.edumimi.com/terms';
  static const _supportEmail = 'hello@edumimi.com';

  Future<void> _openUrl(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        MockToast.error(context, 'Could not open that link. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Help & support'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Text('How can we help?', style: context.pageTitle),
          const SizedBox(height: AppSpacing.item),
          Text(
            'Most account and practice questions can be resolved here without waiting for support.',
            style: context.pageSubtitle,
          ),
          const SizedBox(height: AppSpacing.page),
          MockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Quick actions', style: context.cardTitle),
                const SizedBox(height: AppSpacing.section),
                MockSecondaryButton(
                  label: 'Reset password',
                  expand: true,
                  onPressed: () => context.push('/forgot-password'),
                ),
                const SizedBox(height: AppSpacing.item),
                MockSecondaryButton(
                  label: 'Open full help centre',
                  expand: true,
                  onPressed: () => _openUrl(context, _supportUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          MockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Common questions', style: context.cardTitle),
                const SizedBox(height: AppSpacing.section),
                const _SupportTopic(
                  title: 'Can’t sign in?',
                  description:
                      'Use Reset password, then check your email inbox and spam folder.',
                ),
                const Divider(),
                const _SupportTopic(
                  title: 'Can’t continue an exam?',
                  description:
                      'Return to your dashboard and choose Continue on the in-progress mock.',
                ),
                const Divider(),
                const _SupportTopic(
                  title: 'Need to change your exam plan?',
                  description:
                      'Open Profile, then choose Exam setup to update subjects, years, and goals.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          MockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Still need help?', style: context.cardTitle),
                const SizedBox(height: AppSpacing.item),
                Text(
                  'Email us with your account email, the exam you were using, and a screenshot if possible.',
                  style: context.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.section),
                MockPrimaryButton(
                  label: 'Email support',
                  expand: true,
                  onPressed: () => _openUrl(context, 'mailto:$_supportEmail'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Wrap(
            spacing: AppSpacing.item,
            runSpacing: AppSpacing.item,
            children: [
              TextButton(
                onPressed: () => _openUrl(context, _privacyUrl),
                child: const Text('Privacy'),
              ),
              TextButton(
                onPressed: () => _openUrl(context, _termsUrl),
                child: const Text('Terms'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportTopic extends StatelessWidget {
  const _SupportTopic({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(description, style: context.bodySecondary),
        ],
      ),
    );
  }
}
