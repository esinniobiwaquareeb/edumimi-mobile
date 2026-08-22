import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';

Future<void> toggleMockPushNotifications({
  required WidgetRef ref,
  required BuildContext context,
  required bool enabled,
}) async {
  final service = ref.read(pushNotificationServiceProvider);

  try {
    if (enabled) {
      final success = await service.initialize(GoRouter.of(context));
      if (!success && context.mounted) {
        MockToast.info(context, 'Push notifications are not available on this device yet.');
        return;
      }
    } else {
      await service.disable();
    }
    ref.invalidate(engagementProvider);
    await ref.read(engagementProvider.future);
  } on ApiException catch (error) {
    if (context.mounted) {
      MockToast.error(context, error.message);
    }
  }
}
