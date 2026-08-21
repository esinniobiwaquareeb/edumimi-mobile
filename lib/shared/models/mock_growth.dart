import 'package:equatable/equatable.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class MockPublicChallenge extends Equatable {
  const MockPublicChallenge({
    required this.token,
    required this.challengerName,
    required this.percentScore,
    required this.exam,
  });

  factory MockPublicChallenge.fromJson(Map<String, dynamic> json) {
    return MockPublicChallenge(
      token: json['token']?.toString() ?? '',
      challengerName: json['challengerName']?.toString() ?? 'A friend',
      percentScore: _asDouble(json['percentScore']),
      exam: MockChallengeExam.fromJson(json['exam'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String token;
  final String challengerName;
  final double percentScore;
  final MockChallengeExam exam;

  @override
  List<Object?> get props => [token, challengerName, percentScore, exam];
}

class MockChallengeShare extends Equatable {
  const MockChallengeShare({
    required this.token,
    required this.sharePath,
    required this.shareUrl,
    required this.examTitle,
    required this.percentScore,
  });

  factory MockChallengeShare.fromJson(Map<String, dynamic> json) {
    return MockChallengeShare(
      token: json['token']?.toString() ?? '',
      sharePath: json['sharePath']?.toString() ?? '',
      shareUrl: json['shareUrl']?.toString() ?? '',
      examTitle: json['examTitle']?.toString() ?? '',
      percentScore: _asDouble(json['percentScore']),
    );
  }

  final String token;
  final String sharePath;
  final String shareUrl;
  final String examTitle;
  final num percentScore;

  @override
  List<Object?> get props => [token, sharePath, shareUrl, examTitle, percentScore];
}

class MockChallengeExam extends Equatable {
  const MockChallengeExam({
    required this.title,
    required this.slug,
    this.examTypeSlug,
    this.subjectName,
    this.questionCount,
  });

  factory MockChallengeExam.fromJson(Map<String, dynamic> json) {
    return MockChallengeExam(
      title: json['title']?.toString() ?? 'Practice exam',
      slug: json['slug']?.toString() ?? '',
      examTypeSlug: json['examTypeSlug']?.toString(),
      subjectName: json['subjectName']?.toString(),
      questionCount: json['questionCount'] is num ? (json['questionCount'] as num).toInt() : null,
    );
  }

  final String title;
  final String slug;
  final String? examTypeSlug;
  final String? subjectName;
  final int? questionCount;

  @override
  List<Object?> get props => [title, slug, examTypeSlug];
}

class JambSyllabusModule extends Equatable {
  const JambSyllabusModule({
    required this.recommendedTexts,
    required this.syllabusTopics,
    required this.practiceExams,
  });

  factory JambSyllabusModule.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
      if (value is! List) return const [];
      return value.whereType<Map<String, dynamic>>().map(mapper).toList();
    }

    return JambSyllabusModule(
      recommendedTexts: parseList(json['recommendedTexts'], JambRecommendedText.fromJson),
      syllabusTopics: parseList(json['syllabusTopics'], JambSyllabusTopic.fromJson),
      practiceExams: parseList(json['practiceExams'], JambPracticeExam.fromJson),
    );
  }

  final List<JambRecommendedText> recommendedTexts;
  final List<JambSyllabusTopic> syllabusTopics;
  final List<JambPracticeExam> practiceExams;

  @override
  List<Object?> get props => [recommendedTexts, syllabusTopics, practiceExams];
}

class JambRecommendedText extends Equatable {
  const JambRecommendedText({required this.slug, required this.title, this.author, this.summary});

  factory JambRecommendedText.fromJson(Map<String, dynamic> json) {
    return JambRecommendedText(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString(),
      summary: json['summary']?.toString(),
    );
  }

  final String slug;
  final String title;
  final String? author;
  final String? summary;

  @override
  List<Object?> get props => [slug, title];
}

class JambSyllabusTopic extends Equatable {
  const JambSyllabusTopic({required this.slug, required this.title, this.description, this.subjectName});

  factory JambSyllabusTopic.fromJson(Map<String, dynamic> json) {
    return JambSyllabusTopic(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      subjectName: json['subjectName']?.toString(),
    );
  }

  final String slug;
  final String title;
  final String? description;
  final String? subjectName;

  @override
  List<Object?> get props => [slug, title];
}

class JambPracticeExam extends Equatable {
  const JambPracticeExam({required this.slug, required this.title, this.mode, this.subjectName});

  factory JambPracticeExam.fromJson(Map<String, dynamic> json) {
    return JambPracticeExam(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      mode: json['mode']?.toString(),
      subjectName: json['subjectName']?.toString(),
    );
  }

  final String slug;
  final String title;
  final String? mode;
  final String? subjectName;

  @override
  List<Object?> get props => [slug, title];
}

class PostUtmePackSummary extends Equatable {
  const PostUtmePackSummary({
    required this.slug,
    required this.title,
    required this.universityName,
    this.summary,
    this.listPrice,
    this.practiceExamCount = 0,
    this.brochureUrl,
    this.cutOffMarks,
    this.entryRequirements,
  });

  factory PostUtmePackSummary.fromJson(Map<String, dynamic> json) {
    return PostUtmePackSummary(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      universityName: json['universityName']?.toString() ?? '',
      summary: json['summary']?.toString(),
      listPrice: json['listPrice'] is num ? (json['listPrice'] as num).toDouble() : null,
      practiceExamCount: json['practiceExamCount'] is num ? (json['practiceExamCount'] as num).toInt() : 0,
      brochureUrl: json['brochureUrl']?.toString(),
      cutOffMarks: json['cutOffMarks']?.toString(),
      entryRequirements: json['entryRequirements']?.toString(),
    );
  }

  final String slug;
  final String title;
  final String universityName;
  final String? summary;
  final double? listPrice;
  final int practiceExamCount;
  final String? brochureUrl;
  final String? cutOffMarks;
  final String? entryRequirements;

  @override
  List<Object?> get props => [slug, title, universityName];
}

class PostUtmePackDetail extends Equatable {
  const PostUtmePackDetail({required this.pack, required this.practiceExams});

  factory PostUtmePackDetail.fromJson(Map<String, dynamic> json) {
    final exams = json['practiceExams'];
    return PostUtmePackDetail(
      pack: PostUtmePackSummary.fromJson(json['pack'] as Map<String, dynamic>? ?? {}),
      practiceExams: exams is List
          ? exams
              .whereType<Map<String, dynamic>>()
              .map((item) => MockExam.fromJson({
                    ...item,
                    'totalQuestions': item['totalQuestions'] ?? 0,
                    'durationMinutes': item['durationMinutes'] ?? 30,
                  }))
              .toList()
          : const [],
    );
  }

  final PostUtmePackSummary pack;
  final List<MockExam> practiceExams;

  @override
  List<Object?> get props => [pack, practiceExams];
}

class ParentProgressView extends Equatable {
  const ParentProgressView({
    required this.studentFirstName,
    required this.weakTopics,
    required this.recentAttempts,
    this.examCountdown,
  });

  factory ParentProgressView.fromJson(Map<String, dynamic> json) {
    final insights = json['studyInsights'] as Map<String, dynamic>? ?? {};
    final weakTopicsRaw = insights['weakTopics'];
    final attemptsRaw = json['recentAttempts'];
    return ParentProgressView(
      studentFirstName: json['studentFirstName']?.toString() ?? 'Student',
      examCountdown: insights['examCountdown']?.toString(),
      weakTopics: weakTopicsRaw is List
          ? weakTopicsRaw
              .whereType<Map<String, dynamic>>()
              .map((item) => item['topic']?.toString() ?? '')
              .where((topic) => topic.isNotEmpty)
              .toList()
          : const [],
      recentAttempts: attemptsRaw is List
          ? attemptsRaw.whereType<Map<String, dynamic>>().map(ParentRecentAttempt.fromJson).toList()
          : const [],
    );
  }

  final String studentFirstName;
  final List<String> weakTopics;
  final List<ParentRecentAttempt> recentAttempts;
  final String? examCountdown;

  @override
  List<Object?> get props => [studentFirstName, weakTopics, recentAttempts];
}

class ParentRecentAttempt extends Equatable {
  const ParentRecentAttempt({
    required this.examTitle,
    required this.percentScore,
    this.subjectName,
  });

  factory ParentRecentAttempt.fromJson(Map<String, dynamic> json) {
    return ParentRecentAttempt(
      examTitle: json['examTitle']?.toString() ?? '',
      percentScore: _asDouble(json['percentScore']),
      subjectName: json['subjectName']?.toString(),
    );
  }

  final String examTitle;
  final double percentScore;
  final String? subjectName;

  @override
  List<Object?> get props => [examTitle, percentScore];
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
