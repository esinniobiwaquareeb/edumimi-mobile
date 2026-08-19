import 'package:flutter_test/flutter_test.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/offline/offline_practice_cache.dart';
import 'package:mock_mobile/core/offline/offline_storage.dart';
import 'package:mock_mobile/core/utils/rich_content_utils.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  test('uses mock portal API prefix', () {
    expect(AppConfig.apiPrefix, '/mock-portal');
    expect(AppConfig.appName, 'mock.edumimi');
  });

  test('parses inline and display math tokens', () {
    expect(normalizeMathToken(r'$x^2$')?.expression, 'x^2');
    expect(normalizeMathToken(r'$x^2$')?.displayMode, isFalse);
    expect(normalizeMathToken(r'$$\frac{a}{b}$$')?.displayMode, isTrue);
    expect(normalizeMathToken(r'\(y=mx+c\)')?.expression, 'y=mx+c');
    expect(hasMathContent(r'Solve $x^2 + 1 = 0$'), isTrue);
    expect(splitRichContent(r'If $a$ then $b$'), ['If ', r'$a$', ' then ', r'$b$']);
  });

  test('merges and trims offline practice cache', () async {
    Hive.init('./.dart_tool/test_hive_latex');
    await Hive.openBox<Map>(OfflineStorage.practiceBoxName);
    await OfflineStorage.practiceBox.clear();

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
          questionText: r'Solve $x^2 = 4$',
          options: ['A', 'B'],
          position: 1,
          contentFormat: 'LATEX',
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
    expect(subjects.first.questions.first.contentFormat, 'LATEX');

    await Hive.close();
  });
}
