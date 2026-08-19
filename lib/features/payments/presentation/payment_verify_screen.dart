import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
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
      appBar: AppBar(title: const Text('Payment status')),
      body: verifyAsync.when(
        loading: () => const MockLoadingView(message: 'Confirming payment…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(_paymentVerifyProvider(reference)),
        ),
        data: (purchase) {
          final success = purchase.isSuccessful;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        success ? Icons.check_circle_outline : Icons.hourglass_empty,
                        color: success ? AppColors.success : AppColors.accent,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        success ? 'Payment successful' : 'Payment pending',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        purchase.package?.title ?? 'Mock package',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (purchase.accessEndsAt != null) ...[
                        const SizedBox(height: 8),
                        Text('Access until ${purchase.accessEndsAt}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                MockPrimaryButton(
                  label: success ? 'Start practicing' : 'Back to packages',
                  onPressed: () {
                    ref.invalidate(myPurchasesProvider);
                    ref.invalidate(examFeedProvider);
                    context.go(success ? '/dashboard' : '/packages');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final _paymentVerifyProvider = FutureProvider.autoDispose.family<MockPurchase, String>((ref, reference) {
  return ref.watch(paymentRepositoryProvider).verifyPayment(reference);
});
