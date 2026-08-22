import 'package:equatable/equatable.dart';

class MockUser extends Equatable {
  const MockUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isVerified,
    this.hasTransactionPin = false,
    this.mockProfile,
  });

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'MOCK_CUSTOMER',
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] as bool?,
      hasTransactionPin: json['hasTransactionPin'] as bool? ?? false,
      mockProfile: json['mockProfile'] is Map<String, dynamic>
          ? MockProfile.fromJson(json['mockProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String email;
  final String role;
  final String? name;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool? isVerified;
  final bool hasTransactionPin;
  final MockProfile? mockProfile;

  String get displayName {
    final trimmed = (fullName ?? name ?? '').trim();
    return trimmed.isEmpty ? 'Your account' : trimmed;
  }

  String get firstName {
    final parts = displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'there';
    }
    return parts.first;
  }

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isEmpty) {
      return 'U';
    }
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'name': name,
        'fullName': fullName,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'hasTransactionPin': hasTransactionPin,
        'mockProfile': mockProfile?.toJson(),
      };

  @override
  List<Object?> get props =>
      [id, email, role, name, fullName, phone, avatarUrl, isVerified, hasTransactionPin, mockProfile];
}

class MockProfile extends Equatable {
  const MockProfile({
    this.isVerified,
    this.onboardingCompleted,
    this.interests,
  });

  factory MockProfile.fromJson(Map<String, dynamic> json) {
    return MockProfile(
      isVerified: json['isVerified'] as bool?,
      onboardingCompleted: json['onboardingCompleted'] as bool?,
      interests: json['interests'] is Map<String, dynamic>
          ? MockInterests.fromJson(json['interests'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool? isVerified;
  final bool? onboardingCompleted;
  final MockInterests? interests;

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'onboardingCompleted': onboardingCompleted,
        'interests': interests?.toJson(),
      };

  @override
  List<Object?> get props => [isVerified, onboardingCompleted, interests];
}

class MockInterests extends Equatable {
  const MockInterests({
    this.primaryExamTypeSlug,
    this.subjectTrack,
    this.subjectIds = const [],
    this.prepYear,
    this.paperYearFrom,
    this.paperYearTo,
    this.practiceQuestionCount,
    this.practiceTimerEnabled,
    this.targetScore,
    this.examDate,
  });

  factory MockInterests.fromJson(Map<String, dynamic> json) {
    final subjectIdsRaw = json['subjectIds'];
    return MockInterests(
      primaryExamTypeSlug: json['primaryExamTypeSlug']?.toString(),
      subjectTrack: json['subjectTrack']?.toString(),
      subjectIds: subjectIdsRaw is List
          ? subjectIdsRaw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList()
          : const [],
      prepYear: json['prepYear'] is num ? (json['prepYear'] as num).toInt() : null,
      paperYearFrom: json['paperYearFrom'] is num ? (json['paperYearFrom'] as num).toInt() : null,
      paperYearTo: json['paperYearTo'] is num ? (json['paperYearTo'] as num).toInt() : null,
      practiceQuestionCount:
          json['practiceQuestionCount'] is num ? (json['practiceQuestionCount'] as num).toInt() : null,
      practiceTimerEnabled: json['practiceTimerEnabled'] is bool
          ? json['practiceTimerEnabled'] as bool
          : null,
      targetScore: json['targetScore'] is num ? (json['targetScore'] as num).toInt() : null,
      examDate: json['examDate']?.toString(),
    );
  }

  final String? primaryExamTypeSlug;
  final String? subjectTrack;
  final List<String> subjectIds;
  final int? prepYear;
  final int? paperYearFrom;
  final int? paperYearTo;
  final int? practiceQuestionCount;
  final bool? practiceTimerEnabled;
  final int? targetScore;
  final String? examDate;

  Map<String, dynamic> toJson() => {
        'primaryExamTypeSlug': primaryExamTypeSlug,
        'subjectTrack': subjectTrack,
        'subjectIds': subjectIds,
        'prepYear': prepYear,
        'paperYearFrom': paperYearFrom,
        'paperYearTo': paperYearTo,
        'practiceQuestionCount': practiceQuestionCount,
        'practiceTimerEnabled': practiceTimerEnabled,
        'targetScore': targetScore,
        'examDate': examDate,
      };

  @override
  List<Object?> get props => [
        primaryExamTypeSlug,
        subjectTrack,
        subjectIds,
        prepYear,
        paperYearFrom,
        paperYearTo,
        practiceQuestionCount,
        practiceTimerEnabled,
        targetScore,
        examDate,
      ];
}

class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final MockUser user;

  @override
  List<Object?> get props => [token, user];
}
