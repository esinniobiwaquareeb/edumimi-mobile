import 'package:equatable/equatable.dart';

class MockUser extends Equatable {
  const MockUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.fullName,
    this.avatarUrl,
    this.mockProfile,
  });

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'MOCK_CUSTOMER',
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
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
  final String? avatarUrl;
  final MockProfile? mockProfile;

  String get displayName {
    final trimmed = (fullName ?? name ?? '').trim();
    return trimmed.isEmpty ? 'Your account' : trimmed;
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
        'avatarUrl': avatarUrl,
        'mockProfile': mockProfile?.toJson(),
      };

  @override
  List<Object?> get props => [id, email, role, name, fullName, avatarUrl, mockProfile];
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
    this.targetScore,
    this.examDate,
  });

  factory MockInterests.fromJson(Map<String, dynamic> json) {
    return MockInterests(
      primaryExamTypeSlug: json['primaryExamTypeSlug']?.toString(),
      targetScore: json['targetScore'] is num ? (json['targetScore'] as num).toInt() : null,
      examDate: json['examDate']?.toString(),
    );
  }

  final String? primaryExamTypeSlug;
  final int? targetScore;
  final String? examDate;

  Map<String, dynamic> toJson() => {
        'primaryExamTypeSlug': primaryExamTypeSlug,
        'targetScore': targetScore,
        'examDate': examDate,
      };

  @override
  List<Object?> get props => [primaryExamTypeSlug, targetScore, examDate];
}

class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final MockUser user;

  @override
  List<Object?> get props => [token, user];
}
