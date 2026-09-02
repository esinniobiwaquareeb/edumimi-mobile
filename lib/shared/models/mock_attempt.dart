import 'package:equatable/equatable.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class MockTopicStat extends Equatable {
  const MockTopicStat({
    required this.topic,
    required this.total,
    required this.correct,
    required this.percent,
  });

  factory MockTopicStat.fromJson(Map<String, dynamic> json) {
    return MockTopicStat(
      topic: json['topic']?.toString() ?? '',
      total: _asInt(json['total']),
      correct: _asInt(json['correct']),
      percent: _asInt(json['percent']),
    );
  }

  final String topic;
  final int total;
  final int correct;
  final int percent;

  @override
  List<Object?> get props => [topic, total, correct, percent];
}

class MockRemediationSuggestion extends Equatable {
  const MockRemediationSuggestion({
    required this.topic,
    required this.percent,
    required this.questionCount,
    required this.correctCount,
  });

  factory MockRemediationSuggestion.fromJson(Map<String, dynamic> json) {
    return MockRemediationSuggestion(
      topic: json['topic']?.toString() ?? '',
      percent: _asInt(json['percent']),
      questionCount: _asInt(json['questionCount']),
      correctCount: _asInt(json['correctCount']),
    );
  }

  final String topic;
  final int percent;
  final int questionCount;
  final int correctCount;

  @override
  List<Object?> get props => [topic, percent, questionCount, correctCount];
}

class MockAttempt extends Equatable {
  const MockAttempt({
    required this.id,
    required this.status,
    required this.score,
    required this.totalPossibleScore,
    required this.percentScore,
    this.submittedAt,
    this.durationSeconds,
    this.answers = const {},
    this.topicStats = const [],
    this.remediationSuggestions = const [],
    this.exam,
  });

  factory MockAttempt.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'];
    final answers = <String, int>{};
    if (answersRaw is Map) {
      answersRaw.forEach((key, value) {
        final parsed = value is int ? value : int.tryParse(value.toString());
        if (parsed != null) {
          answers[key.toString()] = parsed;
        }
      });
    }

    final topicStats = json['topicStats'];
    final remediationSuggestions = json['remediationSuggestions'];

    return MockAttempt(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'IN_PROGRESS',
      score: _asNum(json['score']),
      totalPossibleScore: _asNum(json['totalPossibleScore']),
      percentScore: _asNum(json['percentScore']),
      submittedAt: json['submittedAt']?.toString(),
      durationSeconds: json['durationSeconds'] is num
          ? (json['durationSeconds'] as num).toInt()
          : int.tryParse(json['durationSeconds']?.toString() ?? ''),
      answers: answers,
      topicStats: topicStats is List
          ? topicStats
                .whereType<Map<String, dynamic>>()
                .map(MockTopicStat.fromJson)
                .toList()
          : const [],
      remediationSuggestions: remediationSuggestions is List
          ? remediationSuggestions
                .whereType<Map<String, dynamic>>()
                .map(MockRemediationSuggestion.fromJson)
                .toList()
          : const [],
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
  final int? durationSeconds;
  final Map<String, int> answers;
  final List<MockTopicStat> topicStats;
  final List<MockRemediationSuggestion> remediationSuggestions;
  final MockExam? exam;

  bool get isSubmitted => status == 'SUBMITTED';
  bool get isInProgress => status == 'IN_PROGRESS';

  @override
  List<Object?> get props => [id, status, score, percentScore, exam?.id];
}

class MockWeakTopic extends Equatable {
  const MockWeakTopic({
    required this.topic,
    required this.percent,
    required this.questionCount,
    required this.correctCount,
  });

  factory MockWeakTopic.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return MockWeakTopic(
        topic: json['topic']?.toString() ?? '',
        percent: _asInt(json['percent']),
        questionCount: _asInt(json['questionCount']),
        correctCount: _asInt(json['correctCount']),
      );
    }
    if (json is String && json.isNotEmpty) {
      return MockWeakTopic(
        topic: json,
        percent: 0,
        questionCount: 0,
        correctCount: 0,
      );
    }
    return const MockWeakTopic(
      topic: '',
      percent: 0,
      questionCount: 0,
      correctCount: 0,
    );
  }

  final String topic;
  final int percent;
  final int questionCount;
  final int correctCount;

  String get displayLabel => topic.isEmpty ? 'Unknown topic' : topic;

  String get chipLabel => '$displayLabel · $percent%';

  @override
  List<Object?> get props => [topic, percent, questionCount, correctCount];
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
          ? weakTopics
                .map(MockWeakTopic.fromJson)
                .where((topic) => topic.topic.isNotEmpty)
                .toList()
          : const [],
      streakDays: _asInt(json['streakDays']),
      submittedAttempts: _asInt(json['submittedAttempts']),
    );
  }

  final List<MockWeakTopic> weakTopics;
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
  const LeaderboardResponse({
    required this.period,
    required this.entries,
    this.meta,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final entries = payload['entries'];
    final meta = payload['meta'];
    return LeaderboardResponse(
      period: payload['period']?.toString() ?? 'week',
      entries: entries is List
          ? entries
                .whereType<Map>()
                .map(
                  (item) => LeaderboardEntry.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      meta: meta is Map
          ? LeaderboardMeta.fromJson(Map<String, dynamic>.from(meta))
          : null,
    );
  }

  final String period;
  final List<LeaderboardEntry> entries;
  final LeaderboardMeta? meta;

  @override
  List<Object?> get props => [period, entries, meta];
}

class LeaderboardMeta extends Equatable {
  const LeaderboardMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory LeaderboardMeta.fromJson(Map<String, dynamic> json) {
    return LeaderboardMeta(
      total: _asInt(json['total']),
      page: _asInt(json['page']) == 0 ? 1 : _asInt(json['page']),
      limit: _asInt(json['limit']) == 0 ? 10 : _asInt(json['limit']),
      totalPages: _asInt(json['totalPages']) == 0
          ? 1
          : _asInt(json['totalPages']),
    );
  }

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
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
