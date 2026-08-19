import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/shared/models/mock_package.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final _agentCodeController = TextEditingController();
  var _checkoutSlug = '';

  @override
  void dispose() {
    _agentCodeController.dispose();
    super.dispose();
  }

  Future<void> _purchase(MockPackage package, List<MockPurchase> purchases) async {
    if (hasActivePackageSlug(purchases, package.slug)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This package is already active on your account.')),
        );
      }
      return;
    }

    setState(() => _checkoutSlug = package.slug);
    try {
      final checkout = await ref.read(paymentRepositoryProvider).initializeCheckout(
            package.slug,
            agentCode: _agentCodeController.text.trim().isEmpty ? null : _agentCodeController.text.trim(),
          );
      ref.invalidate(myPurchasesProvider);
      if (!mounted) {
        return;
      }
      final authorizationUrl = checkout.authorizationUrl;
      if (authorizationUrl == null || authorizationUrl.isEmpty) {
        context.push('/payments/verify?reference=${checkout.paymentReference}');
        return;
      }
      context.push(
        '/payments/checkout?url=${Uri.encodeComponent(authorizationUrl)}&reference=${Uri.encodeComponent(checkout.paymentReference)}',
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _checkoutSlug = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);
    final purchasesAsync = ref.watch(myPurchasesProvider);
    final currency = NumberFormat.simpleCurrency(name: 'NGN', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock full access')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(packagesProvider);
          ref.invalidate(myPurchasesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Get timed full mocks and premium practice packs.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            MockCard(
              child: TextField(
                controller: _agentCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Agent / tutor code (optional)',
                  hintText: 'AGT-XXXXXX',
                ),
              ),
            ),
            const SizedBox(height: 16),
            packagesAsync.when(
              loading: () => const MockLoadingView(message: 'Loading packages…'),
              error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(packagesProvider)),
              data: (packages) {
                if (packages.isEmpty) {
                  return const MockEmptyState(
                    title: 'No packages yet',
                    message: 'Check back soon for premium practice packs.',
                  );
                }
                final purchases = purchasesAsync.valueOrNull ?? const <MockPurchase>[];
                return Column(
                  children: packages
                      .map(
                        (package) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MockCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(package.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                    ),
                                    if (package.isFeatured) const MockChip(label: 'Featured', tone: MockChipTone.primary),
                                  ],
                                ),
                                if (package.examType != null) ...[
                                  const SizedBox(height: 4),
                                  Text(package.examType!.title, style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  currency.format(package.price),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
                                ),
                                if (package.description?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
                                  MockRichContent(content: package.description),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${package.accessDurationDays} days access · ${package.maxAttempts ?? 'Unlimited'} attempts',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                MockPrimaryButton(
                                  label: hasActivePackageSlug(purchases, package.slug)
                                      ? 'Active'
                                      : hasPendingPackageSlug(purchases, package.slug)
                                          ? 'Payment pending'
                                          : 'Buy now',
                                  isLoading: _checkoutSlug == package.slug,
                                  onPressed: hasActivePackageSlug(purchases, package.slug)
                                      ? null
                                      : () => _purchase(package, purchases),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
