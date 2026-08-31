import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
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

  Future<String?> _promptTransactionPin({
    required bool hasTransactionPin,
  }) async {
    if (!hasTransactionPin) {
      if (!mounted) return null;
      final goToProfile = await MockConfirmDialog.show(
        context,
        title: 'Set up transaction PIN',
        message:
            'Create a 4–6 digit PIN in your profile before making payments.',
        confirmLabel: 'Go to profile',
        cancelLabel: 'Cancel',
      );
      if (goToProfile == true && mounted) {
        context.push('/profile');
      }
      return null;
    }

    final pinController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter transaction PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '4–6 digit PIN',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pin = pinController.text.trim();
                if (pin.length < 4) {
                  return;
                }
                Navigator.of(dialogContext).pop(pin);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    pinController.dispose();
    return result;
  }

  Future<void> _purchase(
    MockPackage package,
    List<MockPurchase> purchases,
  ) async {
    if (hasActivePackageSlug(purchases, package.slug)) {
      if (mounted) {
        MockToast.info(
          context,
          'This package is already active on your account.',
        );
      }
      return;
    }

    final user = ref.read(authControllerProvider).user;
    final transactionPin = await _promptTransactionPin(
      hasTransactionPin: user?.hasTransactionPin ?? false,
    );
    if (transactionPin == null) {
      return;
    }

    setState(() => _checkoutSlug = package.slug);
    try {
      final checkout = await ref
          .read(paymentRepositoryProvider)
          .initializeCheckout(
            package.slug,
            agentCode: _agentCodeController.text.trim().isEmpty
                ? null
                : _agentCodeController.text.trim(),
            transactionPin: transactionPin,
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
        MockToast.error(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        MockToast.error(
          context,
          'Checkout failed. Check your connection and try again.',
        );
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
      appBar: const MockDetailAppBar(title: 'Unlock full access'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(packagesProvider);
          ref.invalidate(myPurchasesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            MockContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MockPageHeader(
                    title: 'Premium packs',
                    subtitle:
                        'Get timed full mocks and extended practice access.',
                  ),
                  const SizedBox(height: AppSpacing.page),
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
                  const SizedBox(height: AppSpacing.page),
                  packagesAsync.when(
                    loading: () =>
                        const MockLoadingView(message: 'Loading packages…'),
                    error: (error, _) => MockErrorView(
                      message: error is ApiException
                          ? error.message
                          : 'Could not load packages. The payment service may be unreachable.',
                      onRetry: () => ref.invalidate(packagesProvider),
                    ),
                    data: (packages) {
                      if (packages.isEmpty) {
                        return const MockEmptyState(
                          title: 'No packages available',
                          message:
                              'Premium packs are not listed right now. Pull down to refresh or try again later.',
                        );
                      }
                      final purchases =
                          purchasesAsync.valueOrNull ?? const <MockPurchase>[];
                      return Column(
                        children: packages
                            .map(
                              (package) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.section,
                                ),
                                child: MockCard(
                                  elevated: package.isFeatured,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              package.title,
                                              style: context.sectionTitle,
                                            ),
                                          ),
                                          if (package.isFeatured)
                                            const MockChip(
                                              label: 'Featured',
                                              tone: MockChipTone.primary,
                                            ),
                                        ],
                                      ),
                                      if (package.examType != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          package.examType!.title,
                                          style: context.bodySecondary,
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.item),
                                      Text(
                                        currency.format(package.price),
                                        style: context.sectionTitle,
                                      ),
                                      if (package.description?.isNotEmpty ??
                                          false) ...[
                                        const SizedBox(height: AppSpacing.item),
                                        MockRichContent(
                                          content: package.description,
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.item),
                                      Text(
                                        '${package.accessDurationDays} days access · ${package.maxAttempts ?? 'Unlimited'} attempts',
                                        style: context.caption,
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.section,
                                      ),
                                      MockPrimaryButton(
                                        label:
                                            hasActivePackageSlug(
                                              purchases,
                                              package.slug,
                                            )
                                            ? 'Active'
                                            : hasPendingPackageSlug(
                                                purchases,
                                                package.slug,
                                              )
                                            ? 'Payment pending'
                                            : 'Buy now',
                                        isLoading:
                                            _checkoutSlug == package.slug,
                                        onPressed:
                                            hasActivePackageSlug(
                                              purchases,
                                              package.slug,
                                            )
                                            ? null
                                            : () =>
                                                  _purchase(package, purchases),
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
          ],
        ),
      ),
    );
  }
}
