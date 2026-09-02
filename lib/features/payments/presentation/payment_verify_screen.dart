import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/utils/mock_date_time.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/shared/models/mock_package.dart';

class PaymentVerifyScreen extends ConsumerWidget {
  const PaymentVerifyScreen({super.key, required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifyAsync = ref.watch(_paymentVerifyProvider(reference));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Payment status'),
      body: verifyAsync.when(
        loading: () => const MockLoadingView(message: 'Confirming payment…'),
        error: (error, _) => MockErrorView(
          message: error is ApiException
              ? error.message
              : 'Could not confirm payment. The server may be unreachable — try again shortly.',
          onRetry: () => ref.invalidate(_paymentVerifyProvider(reference)),
        ),
        data: (purchase) {
          final success = purchase.isSuccessful;
          final pending = purchase.isPending;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MockCard(
                  elevated: success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        success
                            ? Icons.check_circle_outline
                            : pending
                            ? Icons.schedule_outlined
                            : Icons.error_outline,
                        size: 40,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Text(
                        success
                            ? 'Payment successful'
                            : pending
                            ? 'Payment pending'
                            : 'Payment not completed',
                        style: context.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.item),
                      Text(
                        purchase.package?.title ?? 'Mock package',
                        style: context.bodySecondary,
                      ),
                      if (pending) ...[
                        const SizedBox(height: AppSpacing.item),
                        Text(
                          'Paystack is still processing this payment. Pull to refresh on the packages screen or tap below to check again.',
                          style: context.caption,
                        ),
                      ],
                      if (purchase.accessEndsAt != null) ...[
                        const SizedBox(height: AppSpacing.item),
                        Text(
                          'Access until ${MockDateTime.dateTime(purchase.accessEndsAt)}',
                          style: context.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (pending) ...[
                  MockSplitActionRow(
                    start: MockSecondaryButton(
                      label: 'Check again',
                      onPressed: () =>
                          ref.invalidate(_paymentVerifyProvider(reference)),
                      expand: true,
                    ),
                    end: MockPrimaryButton(
                      label: 'Back to packages',
                      onPressed: () {
                        ref.invalidate(myPurchasesProvider);
                        ref.invalidate(examFeedProvider);
                        context.go('/packages');
                      },
                      expand: true,
                    ),
                  ),
                ] else
                  MockPrimaryButton(
                    label: success ? 'Start practicing' : 'Back to packages',
                    onPressed: () {
                      ref.invalidate(myPurchasesProvider);
                      ref.invalidate(examFeedProvider);
                      context.go(success ? '/dashboard' : '/packages');
                    },
                    expand: true,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final _paymentVerifyProvider = FutureProvider.autoDispose
    .family<MockPurchase, String>((ref, reference) {
      return ref.watch(paymentRepositoryProvider).verifyPayment(reference);
    });
