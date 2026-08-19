import 'package:mock_mobile/core/offline/offline_storage.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

const _maxQuestionsPerSubject = 24;

class OfflineSubjectCache {
  const OfflineSubjectCache({
    required this.subjectKey,
    required this.subjectName,
    required this.examTypeSlug,
    required this.updatedAt,
    required this.questions,
  });

  factory OfflineSubjectCache.fromMap(Map map) {
    final questionsRaw = map['questions'];
    final questions = questionsRaw is List
        ? questionsRaw
            .whereType<Map>()
            .map((item) => MockQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : const <MockQuestion>[];

    return OfflineSubjectCache(
      subjectKey: map['subjectKey']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? 'Practice',
      examTypeSlug: map['examTypeSlug']?.toString(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      questions: questions,
    );
  }

  final String subjectKey;
  final String subjectName;
  final String? examTypeSlug;
  final DateTime updatedAt;
  final List<MockQuestion> questions;

  Map<String, dynamic> toMap() {
    return {
      'subjectKey': subjectKey,
      'subjectName': subjectName,
      'examTypeSlug': examTypeSlug,
      'updatedAt': updatedAt.toIso8601String(),
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }
}

class OfflinePracticeCache {
  String _subjectKey(MockExam exam) {
    return exam.subject?.slug ?? exam.examType?.slug ?? exam.id;
  }

  Future<void> cacheExamQuestions(MockExam exam) async {
    if (exam.questions.isEmpty) {
      return;
    }

    final subjectKey = _subjectKey(exam);
    final box = OfflineStorage.practiceBox;
    final existing = box.get(subjectKey);
    final existingCache = existing == null ? null : OfflineSubjectCache.fromMap(existing);
    final merged = <MockQuestion>[...(existingCache?.questions ?? const [])];

    for (final question in exam.questions) {
      if (merged.any((item) => item.id == question.id)) {
        continue;
      }
      merged.add(question);
    }

    final trimmed = merged.length <= _maxQuestionsPerSubject
        ? merged
        : merged.sublist(merged.length - _maxQuestionsPerSubject);

    final cache = OfflineSubjectCache(
      subjectKey: subjectKey,
      subjectName: exam.subject?.name ?? exam.title,
      examTypeSlug: exam.examType?.slug,
      updatedAt: DateTime.now(),
      questions: trimmed,
    );

    await box.put(subjectKey, cache.toMap());
  }

  List<OfflineSubjectCache> listSubjects() {
    return OfflineStorage.practiceBox.values
        .map(OfflineSubjectCache.fromMap)
        .toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  List<MockQuestion> questionsForSubject(String subjectKey) {
    final raw = OfflineStorage.practiceBox.get(subjectKey);
    if (raw == null) {
      return const [];
    }
    return OfflineSubjectCache.fromMap(raw).questions;
  }
}
