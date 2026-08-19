import 'package:equatable/equatable.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class MockAttempt extends Equatable {
  const MockAttempt({
    required this.id,
    required this.status,
    required this.score,
    required this.totalPossibleScore,
    required this.percentScore,
    this.submittedAt,
    this.exam,
  });

  factory MockAttempt.fromJson(Map<String, dynamic> json) {
    return MockAttempt(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'IN_PROGRESS',
      score: _asNum(json['score']),
      totalPossibleScore: _asNum(json['totalPossibleScore']),
      percentScore: _asNum(json['percentScore']),
      submittedAt: json['submittedAt']?.toString(),
      exam: json['exam'] is Map<String, dynamic>
          ? MockExam.fromJson(json['exam'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String status;
  final num score;
  final num totalPossibleScore;
  final num percentScore;
  final String? submittedAt;
  final MockExam? exam;

  bool get isSubmitted => status == 'SUBMITTED';
  bool get isInProgress => status == 'IN_PROGRESS';

  @override
  List<Object?> get props => [id, status, score, percentScore, exam?.id];
}

class MockStudyInsights extends Equatable {
  const MockStudyInsights({
    required this.weakTopics,
    required this.streakDays,
    required this.submittedAttempts,
  });

  factory MockStudyInsights.fromJson(Map<String, dynamic> json) {
    final weakTopics = json['weakTopics'];
    return MockStudyInsights(
      weakTopics: weakTopics is List
          ? weakTopics.map((item) => item.toString()).toList()
          : const [],
      streakDays: _asInt(json['streakDays']),
      submittedAttempts: _asInt(json['submittedAttempts']),
    );
  }

  final List<String> weakTopics;
  final int streakDays;
  final int submittedAttempts;

  @override
  List<Object?> get props => [weakTopics, streakDays, submittedAttempts];
}

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.percentScore,
    required this.examTitle,
    required this.submittedAt,
    this.subjectName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _asInt(json['rank']),
      displayName: json['displayName']?.toString() ?? 'Student',
      percentScore: _asDouble(json['percentScore']),
      examTitle: json['examTitle']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ?? '',
      subjectName: json['subjectName']?.toString(),
    );
  }

  final int rank;
  final String displayName;
  final double percentScore;
  final String examTitle;
  final String submittedAt;
  final String? subjectName;

  @override
  List<Object?> get props => [rank, displayName, percentScore];
}

class LeaderboardResponse extends Equatable {
  const LeaderboardResponse({required this.period, required this.entries});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    return LeaderboardResponse(
      period: json['period']?.toString() ?? 'week',
      entries: entries is List
          ? entries
              .whereType<Map<String, dynamic>>()
              .map(LeaderboardEntry.fromJson)
              .toList()
          : const [],
    );
  }

  final String period;
  final List<LeaderboardEntry> entries;

  @override
  List<Object?> get props => [period, entries];
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

num _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
