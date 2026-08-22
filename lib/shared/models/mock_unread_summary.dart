import 'package:equatable/equatable.dart';

class MockUnreadSummary extends Equatable {
  const MockUnreadSummary({
    required this.communityUnread,
    required this.activityUnread,
    required this.pushPrompt,
    required this.notificationUnread,
  });

  factory MockUnreadSummary.fromJson(Map<String, dynamic> json) {
    return MockUnreadSummary(
      communityUnread: _asInt(json['communityUnread']),
      activityUnread: _asInt(json['activityUnread']),
      pushPrompt: json['pushPrompt'] == true,
      notificationUnread: _asInt(json['notificationUnread']),
    );
  }

  static const empty = MockUnreadSummary(
    communityUnread: 0,
    activityUnread: 0,
    pushPrompt: false,
    notificationUnread: 0,
  );

  final int communityUnread;
  final int activityUnread;
  final bool pushPrompt;
  final int notificationUnread;

  @override
  List<Object?> get props => [communityUnread, activityUnread, pushPrompt, notificationUnread];
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
