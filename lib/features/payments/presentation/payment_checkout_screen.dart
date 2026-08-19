import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.navigate;
            }

            final reference = uri.queryParameters['reference'] ??
                uri.queryParameters['trxref'] ??
                (uri.path.contains('verify') ? widget.paymentReference : null);

            if (reference != null && reference.startsWith('MOCK-')) {
              context.go('/payments/verify?reference=${Uri.encodeComponent(reference)}');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/packages'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const MockLoadingView(message: 'Opening Paystack…'),
        ],
      ),
    );
  }
}
