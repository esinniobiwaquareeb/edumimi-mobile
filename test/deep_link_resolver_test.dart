import 'package:flutter_test/flutter_test.dart';
import 'package:mock_mobile/core/router/deep_link_resolver.dart';

void main() {
  group('DeepLinkResolver', () {
    test('maps custom scheme verify-email links', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://app/verify-email?token=abc123'),
        ),
        '/verify-email?token=abc123',
      );
    });

    test('maps custom scheme reset-password links', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://app/reset-password?token=reset-token'),
        ),
        '/reset-password?token=reset-token',
      );
    });

    test('maps custom scheme challenge and parent token paths', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://app/challenge/challenge-token'),
        ),
        '/challenge/challenge-token',
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://app/parent/parent-token'),
        ),
        '/parent/parent-token',
      );
    });

    test('maps custom scheme payment verify links', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://app/payments/verify?reference=pay-ref'),
        ),
        '/payments/verify?reference=pay-ref',
      );
    });

    test('maps HTTPS web auth paths to mobile routes', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://mock.edumimi.com/auth/verify-email?token=abc123'),
        ),
        '/verify-email?token=abc123',
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse(
            'https://mock.edumimi.com/auth/reset-password?token=reset-token',
          ),
        ),
        '/reset-password?token=reset-token',
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://mock.edumimi.com/auth/register?ref=ADA123'),
        ),
        '/signup?ref=ADA123',
      );
    });

    test('maps HTTPS challenge, parent, and payment links', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://mock.edumimi.com/challenge/challenge-token'),
        ),
        '/challenge/challenge-token',
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://mock.edumimi.com/parent/parent-token'),
        ),
        '/parent/parent-token',
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse(
            'https://mock.edumimi.com/payments/verify?reference=pay-ref',
          ),
        ),
        '/payments/verify?reference=pay-ref',
      );
    });

    test('ignores unsupported hosts and paths', () {
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('mockedumimi://other/verify-email?token=abc'),
        ),
        isNull,
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://example.com/challenge/token'),
        ),
        isNull,
      );
      expect(
        DeepLinkResolver.resolveRoute(
          Uri.parse('https://mock.edumimi.com/dashboard'),
        ),
        isNull,
      );
    });
  });
}
