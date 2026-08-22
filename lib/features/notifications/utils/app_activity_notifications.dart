import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_package.dart';

enum AppActivityNotificationKind { purchase, attempt }

class AppActivityNotification {
  const AppActivityNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.timestamp,
    this.route,
  });

  final String id;
  final AppActivityNotificationKind kind;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? route;
}

List<AppActivityNotification> buildAppActivityNotifications({
  required List<MockPurchase> purchases,
  required List<MockAttempt> attempts,
}) {
  final items = <AppActivityNotification>[];

  for (final purchase in purchases) {
    final packageTitle = purchase.package?.title ?? 'Practice package';
    final timestamp = _parseTimestamp(purchase.accessStartsAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final (title, message, route) = switch (purchase.status.toUpperCase()) {
      'SUCCESSFUL' => (
          'Payment successful',
          '$packageTitle is now active on your account.',
          purchase.isActive ? '/packages' : null,
        ),
      'PENDING' => (
          'Payment processing',
          'We are confirming your payment for $packageTitle.',
          purchase.paymentReference?.isNotEmpty == true
              ? '/payments/verify?reference=${Uri.encodeComponent(purchase.paymentReference!)}'
              : '/packages',
        ),
      'FAILED' => (
          'Payment failed',
          'Your payment for $packageTitle did not go through. Try again from Packages.',
          '/packages',
        ),
      _ => (
          'Purchase update',
          '$packageTitle · ${purchase.status.replaceAll('_', ' ').toLowerCase()}',
          '/packages',
        ),
    };

    if (purchase.paymentReference?.isNotEmpty == true || purchase.isSuccessful) {
      items.add(
        AppActivityNotification(
          id: 'purchase-${purchase.id}',
          kind: AppActivityNotificationKind.purchase,
          title: title,
          message: message,
          timestamp: timestamp,
          route: route,
        ),
      );
    }
  }

  for (final attempt in attempts.where((item) => item.isSubmitted)) {
    final submittedAt = _parseTimestamp(attempt.submittedAt);
    items.add(
      AppActivityNotification(
        id: 'attempt-${attempt.id}',
        kind: AppActivityNotificationKind.attempt,
        title: 'Score submitted',
        message: '${attempt.exam?.title ?? 'Mock exam'} · ${attempt.percentScore}% (${attempt.score}/${attempt.totalPossibleScore})',
        timestamp: submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        route: '/results/${attempt.id}',
      ),
    );
  }

  items.sort((left, right) => right.timestamp.compareTo(left.timestamp));
  return items;
}

DateTime? _parseTimestamp(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
