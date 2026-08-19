import 'package:equatable/equatable.dart';

class MockExamType extends Equatable {
  const MockExamType({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.subjects = const [],
  });

  factory MockExamType.fromJson(Map<String, dynamic> json) {
    final subjectsRaw = json['subjects'];
    return MockExamType(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Exam',
      description: json['description']?.toString(),
      subjects: subjectsRaw is List
          ? subjectsRaw.whereType<Map<String, dynamic>>().map(MockSubject.fromJson).toList()
          : const [],
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? description;
  final List<MockSubject> subjects;

  @override
  List<Object?> get props => [id, slug, title, description, subjects];
}

class MockSubject extends Equatable {
  const MockSubject({required this.id, required this.name, required this.slug, this.sortOrder});

  factory MockSubject.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MockSubject(id: '', name: '', slug: '');
    }
    return MockSubject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sortOrder: json['sortOrder'] is num ? (json['sortOrder'] as num).toInt() : null,
    );
  }

  final String id;
  final String name;
  final String slug;
  final int? sortOrder;

  @override
  List<Object?> get props => [id, name, slug, sortOrder];
}

class MockExam extends Equatable {
  const MockExam({
    required this.id,
    required this.title,
    required this.slug,
    required this.mode,
    required this.durationMinutes,
    required this.totalQuestions,
    this.description,
    this.instructions,
    this.difficulty,
    this.totalMarks = 0,
    this.accessState,
    this.recommendationReason,
    this.percentScore,
    this.examYear,
    this.examType,
    this.subject,
    this.questions = const [],
  });

  factory MockExam.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    return MockExam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Practice',
      slug: json['slug']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'PRACTICE',
      durationMinutes: _asInt(json['durationMinutes']),
      totalQuestions: _asInt(json['totalQuestions']),
      description: json['description']?.toString(),
      instructions: json['instructions']?.toString(),
      difficulty: json['difficulty']?.toString(),
      totalMarks: _asInt(json['totalMarks']),
      accessState: json['accessState']?.toString(),
      recommendationReason: json['recommendationReason']?.toString(),
      percentScore: json['percentScore'] is num ? (json['percentScore'] as num).toDouble() : null,
      examYear: json['examYear'] is num ? (json['examYear'] as num).toInt() : int.tryParse(json['examYear']?.toString() ?? ''),
      examType: json['examType'] is Map<String, dynamic>
          ? MockExamType.fromJson(json['examType'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] is Map<String, dynamic>
          ? MockSubject.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
      questions: questions is List
          ? questions
              .whereType<Map<String, dynamic>>()
              .map(MockQuestion.fromJson)
              .toList()
          : const [],
    );
  }

  final String id;
  final String title;
  final String slug;
  final String mode;
  final int durationMinutes;
  final int totalQuestions;
  final String? description;
  final String? instructions;
  final String? difficulty;
  final int totalMarks;
  final String? accessState;
  final String? recommendationReason;
  final double? percentScore;
  final int? examYear;
  final MockExamType? examType;
  final MockSubject? subject;
  final List<MockQuestion> questions;

  bool get isLocked => accessState == 'LOCKED';

  bool get isFreePractice => mode == 'PRACTICE' || mode == 'TOPIC_DRILL';

  int get displayQuestionCount => questions.isNotEmpty ? questions.length : totalQuestions;

  int get displayTotalMarks {
    if (totalMarks > 0) {
      return totalMarks;
    }
    if (questions.isNotEmpty) {
      final pointsTotal = questions.fold<int>(0, (sum, question) => sum + (question.points ?? 1));
      if (pointsTotal > 0) {
        return pointsTotal;
      }
    }
    return totalQuestions;
  }

  String get examTypeLabel => examType?.title ?? 'General';
  String get subjectLabel => subject?.name ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'mode': mode,
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (difficulty != null) 'difficulty': difficulty,
      if (totalMarks > 0) 'totalMarks': totalMarks,
      if (accessState != null) 'accessState': accessState,
      if (recommendationReason != null) 'recommendationReason': recommendationReason,
      if (percentScore != null) 'percentScore': percentScore,
      if (examType != null)
        'examType': {
          'id': examType!.id,
          'slug': examType!.slug,
          'title': examType!.title,
          if (examType!.description != null) 'description': examType!.description,
        },
      if (subject != null)
        'subject': {
          'id': subject!.id,
          'name': subject!.name,
          'slug': subject!.slug,
        },
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, slug, title, mode, accessState];
}

class MockQuestion extends Equatable {
  const MockQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.position,
    this.instructions,
    this.contentFormat,
    this.questionGroupKey,
    this.questionGroupTitle,
    this.questionGroupText,
    this.questionGroupInstructions,
    this.imageUrl,
    this.points,
    this.correctOptionIndex,
    this.explanation,
    this.isLocked = false,
  });

  factory MockQuestion.fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    return MockQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      options: options is List ? options.map((item) => item.toString()).toList() : const [],
      position: _asInt(json['position']),
      instructions: json['instructions']?.toString(),
      contentFormat: json['contentFormat']?.toString(),
      questionGroupKey: json['questionGroupKey']?.toString(),
      questionGroupTitle: json['questionGroupTitle']?.toString(),
      questionGroupText: json['questionGroupText']?.toString(),
      questionGroupInstructions: json['questionGroupInstructions']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      points: json['points'] is num ? (json['points'] as num).toInt() : _asInt(json['points']),
      correctOptionIndex: json['correctOptionIndex'] is num
          ? (json['correctOptionIndex'] as num).toInt()
          : int.tryParse(json['correctOptionIndex']?.toString() ?? ''),
      explanation: json['explanation']?.toString(),
      isLocked: json['isLocked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'position': position,
      if (instructions != null) 'instructions': instructions,
      if (contentFormat != null) 'contentFormat': contentFormat,
      if (questionGroupKey != null) 'questionGroupKey': questionGroupKey,
      if (questionGroupTitle != null) 'questionGroupTitle': questionGroupTitle,
      if (questionGroupText != null) 'questionGroupText': questionGroupText,
      if (questionGroupInstructions != null) 'questionGroupInstructions': questionGroupInstructions,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (points != null) 'points': points,
      if (correctOptionIndex != null) 'correctOptionIndex': correctOptionIndex,
      if (explanation != null) 'explanation': explanation,
      if (isLocked) 'isLocked': isLocked,
    };
  }

  final String id;
  final String questionText;
  final List<String> options;
  final int position;
  final String? instructions;
  final String? contentFormat;
  final String? questionGroupKey;
  final String? questionGroupTitle;
  final String? questionGroupText;
  final String? questionGroupInstructions;
  final String? imageUrl;
  final int? points;
  final int? correctOptionIndex;
  final String? explanation;
  final bool isLocked;

  bool get hasQuestionGroup =>
      (questionGroupTitle?.isNotEmpty ?? false) ||
      (questionGroupText?.isNotEmpty ?? false) ||
      (questionGroupInstructions?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [id, position];
}

class MockExamFeed extends Equatable {
  const MockExamFeed({
    required this.onboardingCompleted,
    required this.recommended,
    required this.other,
  });

  factory MockExamFeed.fromJson(Map<String, dynamic> json) {
    List<MockExam> parseList(Object? value) {
      if (value is! List) {
        return const [];
      }
      return value
          .whereType<Map<String, dynamic>>()
          .map(MockExam.fromJson)
          .toList();
    }

    return MockExamFeed(
      onboardingCompleted: json['onboardingCompleted'] == true,
      recommended: parseList(json['recommended']),
      other: parseList(json['other']),
    );
  }

  final bool onboardingCompleted;
  final List<MockExam> recommended;
  final List<MockExam> other;

  List<MockExam> get all => [...recommended, ...other];

  @override
  List<Object?> get props => [onboardingCompleted, recommended, other];
}

class StartAttemptResponse extends Equatable {
  const StartAttemptResponse({
    required this.attemptId,
    required this.exam,
    this.resumed = false,
  });

  factory StartAttemptResponse.fromJson(Map<String, dynamic> json) {
    return StartAttemptResponse(
      attemptId: json['attemptId']?.toString() ?? '',
      exam: MockExam.fromJson(json['exam'] as Map<String, dynamic>? ?? {}),
      resumed: json['resumed'] == true,
    );
  }

  final String attemptId;
  final MockExam exam;
  final bool resumed;

  @override
  List<Object?> get props => [attemptId, exam, resumed];
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
