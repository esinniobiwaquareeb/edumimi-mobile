import 'package:equatable/equatable.dart';

class MockEngagement extends Equatable {
  const MockEngagement({
    required this.practiceStreakDays,
    required this.pushNotificationsEnabled,
    required this.pushNotificationsSupported,
    required this.fcmNotificationsEnabled,
    required this.fcmNotificationsSupported,
    this.referralCode,
    this.streakAtRisk = false,
  });

  factory MockEngagement.fromJson(Map<String, dynamic> json) {
    return MockEngagement(
      practiceStreakDays: _asInt(json['practiceStreakDays']),
      referralCode: json['referralCode']?.toString(),
      streakAtRisk: json['streakAtRisk'] == true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] == true,
      pushNotificationsSupported: json['pushNotificationsSupported'] == true,
      fcmNotificationsEnabled: json['fcmNotificationsEnabled'] == true,
      fcmNotificationsSupported: json['fcmNotificationsSupported'] == true,
    );
  }

  final int practiceStreakDays;
  final String? referralCode;
  final bool streakAtRisk;
  final bool pushNotificationsEnabled;
  final bool pushNotificationsSupported;
  final bool fcmNotificationsEnabled;
  final bool fcmNotificationsSupported;

  @override
  List<Object?> get props => [practiceStreakDays, fcmNotificationsEnabled];
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
