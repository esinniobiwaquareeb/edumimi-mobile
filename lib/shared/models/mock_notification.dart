import 'package:equatable/equatable.dart';

enum MockNotificationCategory { purchase, attempt, system, referral }

enum MockNotificationType { info, success, warning, error }

class MockNotification extends Equatable {
  const MockNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.route,
    this.metadata,
    this.readAt,
  });

  factory MockNotification.fromJson(Map<String, dynamic> json) {
    return MockNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      category: _parseCategory(json['category']?.toString()),
      isRead: json['isRead'] == true,
      route: json['route']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['createdAt']?.toString() ?? '',
      readAt: json['readAt']?.toString(),
    );
  }

  final String id;
  final String title;
  final String message;
  final MockNotificationType type;
  final MockNotificationCategory category;
  final bool isRead;
  final String? route;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String? readAt;

  @override
  List<Object?> get props => [id, isRead, createdAt];
}

MockNotificationType _parseType(String? value) {
  return switch (value?.toUpperCase()) {
    'SUCCESS' => MockNotificationType.success,
    'WARNING' => MockNotificationType.warning,
    'ERROR' => MockNotificationType.error,
    _ => MockNotificationType.info,
  };
}

MockNotificationCategory _parseCategory(String? value) {
  return switch (value?.toUpperCase()) {
    'PURCHASE' => MockNotificationCategory.purchase,
    'ATTEMPT' => MockNotificationCategory.attempt,
    'REFERRAL' => MockNotificationCategory.referral,
    _ => MockNotificationCategory.system,
  };
}
