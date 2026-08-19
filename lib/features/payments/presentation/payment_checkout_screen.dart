import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  const PaymentCheckoutScreen({super.key, required this.authorizationUrl, required this.paymentReference});

  final String authorizationUrl;
  final String paymentReference;

  @override
  ConsumerState<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  late final WebViewController _controller;
  var _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _loadError = null;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _loadError = error.description.isNotEmpty
                  ? error.description
                  : 'Could not load Paystack checkout. Check your connection.';
            });
          },
          onNavigationRequest: (request) {
            final redirect = _resolvePaymentRedirect(request.url);
            if (redirect != null) {
              context.go(redirect);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  String? _resolvePaymentRedirect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final webHost = Uri.parse(AppConfig.webShareOrigin).host;
    final isVerifyPath = uri.path.contains('/payments/verify');
    final isWebCallback = uri.host == webHost && isVerifyPath;
    final isMockReference = uri.queryParameters.containsKey('reference') ||
        uri.queryParameters.containsKey('trxref');

    if (isWebCallback || (isVerifyPath && isMockReference)) {
      final reference = uri.queryParameters['reference'] ??
          uri.queryParameters['trxref'] ??
          widget.paymentReference;
      if (reference.isNotEmpty) {
        return '/payments/verify?reference=${Uri.encodeComponent(reference)}';
      }
    }

    if (isMockReference && uri.queryParameters.values.any((value) => value.startsWith('MOCK-'))) {
      final reference = uri.queryParameters['reference'] ?? uri.queryParameters['trxref'] ?? widget.paymentReference;
      return '/payments/verify?reference=${Uri.encodeComponent(reference)}';
    }

    return null;
  }

  Future<void> _confirmLeaveCheckout() async {
    final confirmed = await MockConfirmDialog.show(
      context,
      title: MockVoice.cancelPaymentTitle,
      message: MockVoice.cancelPaymentDesc,
      confirmLabel: MockVoice.cancelPaymentConfirm,
      cancelLabel: MockVoice.cancelPaymentStay,
      variant: MockConfirmDialogVariant.warning,
    );
    if (confirmed && mounted) {
      context.go('/packages');
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    await _controller.loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _confirmLeaveCheckout();
      },
      child: Scaffold(
        appBar: MockDetailAppBar(
          title: 'Complete payment',
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmLeaveCheckout,
          ),
        ),
        body: Stack(
          children: [
            if (_loadError == null) WebViewWidget(controller: _controller),
            if (_loadError != null)
              MockErrorView(
                message: _loadError!,
                onRetry: _retryLoad,
              ),
            if (_isLoading && _loadError == null) const MockLoadingView(message: 'Opening Paystack…'),
          ],
        ),
      ),
    );
  }
}
