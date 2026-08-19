import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/offline/offline_practice_cache.dart';
import 'package:mock_mobile/core/offline/offline_storage.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

void main() {
  test('uses mock portal API prefix', () {
    expect(AppConfig.apiPrefix, '/mock-portal');
    expect(AppConfig.appName, 'mock.edumimi');
  });

  test('merges and trims offline practice cache', () async {
    Hive.init('./.dart_tool/test_hive');
    await Hive.openBox<Map>(OfflineStorage.practiceBoxName);

    final cache = OfflinePracticeCache();
    final exam = MockExam(
      id: 'exam-1',
      title: 'Biology drill',
      slug: 'biology-drill',
      mode: 'PRACTICE',
      durationMinutes: 30,
      totalQuestions: 2,
      subject: const MockSubject(id: 'sub-1', name: 'Biology', slug: 'biology'),
      questions: const [
        MockQuestion(
          id: 'q1',
          questionText: 'Question 1',
          options: ['A', 'B'],
          position: 1,
        ),
        MockQuestion(
          id: 'q2',
          questionText: 'Question 2',
          options: ['A', 'B'],
          position: 2,
        ),
      ],
    );

    await cache.cacheExamQuestions(exam);
    await cache.cacheExamQuestions(exam);

    final subjects = cache.listSubjects();
    expect(subjects, hasLength(1));
    expect(subjects.first.questions, hasLength(2));
    expect(subjects.first.subjectName, 'Biology');

    await Hive.close();
  });
}
