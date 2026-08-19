import 'package:flutter_test/flutter_test.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/offline/exam_session_store.dart';
import 'package:mock_mobile/core/offline/offline_practice_cache.dart';
import 'package:mock_mobile/core/offline/offline_storage.dart';
import 'package:mock_mobile/core/storage/app_prefs_storage.dart';
import 'package:mock_mobile/core/utils/rich_content_utils.dart';
import 'package:mock_mobile/core/utils/share_utils.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  test('uses mock portal API prefix', () {
    expect(AppConfig.apiPrefix, '/mock-portal');
    expect(AppConfig.appName, 'Edumimi Mock');
  });

  test('returns time-based greeting labels', () {
    expect(mockTimeBasedGreeting(DateTime(2026, 1, 1, 8)), 'Good morning');
    expect(mockTimeBasedGreeting(DateTime(2026, 1, 1, 12)), 'Good afternoon');
    expect(mockTimeBasedGreeting(DateTime(2026, 1, 1, 18)), 'Good evening');
  });

  test('derives first name from display name', () {
    const user = MockUser(
      id: '1',
      email: 'ada@example.com',
      role: 'MOCK_CUSTOMER',
      fullName: 'Ada Lovelace',
    );
    expect(user.firstName, 'Ada');
    expect(user.initials, 'AL');
  });

  test('parses inline and display math tokens', () {
    expect(normalizeMathToken(r'$x^2$')?.expression, 'x^2');
    expect(normalizeMathToken(r'$x^2$')?.displayMode, isFalse);
    expect(normalizeMathToken(r'$$\frac{a}{b}$$')?.displayMode, isTrue);
    expect(normalizeMathToken(r'\(y=mx+c\)')?.expression, 'y=mx+c');
    expect(hasMathContent(r'Solve $x^2 + 1 = 0$'), isTrue);
    expect(splitRichContent(r'If $a$ then $b$'), ['If ', r'$a$', ' then ', r'$b$']);
  });

  test('persists onboarding seen flag', () async {
    Hive.init('./.dart_tool/test_hive_onboarding');
    await Hive.openBox<dynamic>(OfflineStorage.appPrefsBoxName);
    final box = Hive.box<dynamic>(OfflineStorage.appPrefsBoxName);
    await box.clear();

    final storage = AppPrefsStorage();
    expect(await storage.hasSeenOnboarding(), isFalse);
    await storage.setOnboardingSeen();
    expect(await storage.hasSeenOnboarding(), isTrue);

    await Hive.close();
  });

  test('parses weak topics from study insights payload', () {
    final insights = MockStudyInsights.fromJson({
      'streakDays': 3,
      'submittedAttempts': 12,
      'weakTopics': [
        {
          'topic': 'Physics',
          'percent': 0,
          'questionCount': 115,
          'correctCount': 0,
        },
        {
          'topic': 'Algebra',
          'percent': 42,
          'questionCount': 20,
          'correctCount': 8,
        },
      ],
    });

    expect(insights.weakTopics, hasLength(2));
    expect(insights.weakTopics.first.topic, 'Physics');
    expect(insights.weakTopics.first.chipLabel, 'Physics · 0%');
    expect(insights.weakTopics.last.percent, 42);
  });

  test('builds share messages aligned with web copy', () {
    expect(
      buildMockResultShareMessage(
        examTitle: 'JAMB Physics',
        percentScore: 82,
        referralLink: 'https://mock.edumimi.com/?ref=ADA123',
      ),
      contains('82%'),
    );
    expect(
      buildMockResultShareMessage(
        examTitle: 'JAMB Physics',
        percentScore: 82,
        referralLink: 'https://mock.edumimi.com/?ref=ADA123',
      ),
      contains('https://mock.edumimi.com/?ref=ADA123'),
    );
    expect(
      buildChallengeShareMessage(
        challengerName: 'Ada',
        examTitle: 'JAMB Physics',
        percentScore: 82,
        shareUrl: 'https://mock.edumimi.com/challenge/abc',
      ),
      'Ada scored 82% on JAMB Physics on Edumimi. Take the same mock: https://mock.edumimi.com/challenge/abc',
    );
    expect(
      buildReferralShareMessage(referralLink: 'https://mock.edumimi.com/?ref=ADA123'),
      'Join me on Edumimi Mock practice: https://mock.edumimi.com/?ref=ADA123',
    );
  });

  test('detects preview attempts from locked questions', () {
    final previewAttempt = MockAttempt.fromJson({
      'id': 'attempt-preview',
      'status': 'SUBMITTED',
      'score': 4,
      'totalPossibleScore': 10,
      'percentScore': 40,
      'exam': {
        'id': 'exam-1',
        'title': 'Preview mock',
        'slug': 'preview-mock',
        'mode': 'MOCK',
        'durationMinutes': 30,
        'totalQuestions': 2,
        'questions': [
          {
            'id': 'q1',
            'questionText': 'Q1',
            'options': ['A', 'B'],
            'position': 1,
            'isLocked': false,
          },
          {
            'id': 'q2',
            'questionText': 'Q2',
            'options': ['A', 'B'],
            'position': 2,
            'isLocked': true,
          },
        ],
      },
    });

    expect(isPreviewAttempt(previewAttempt), isTrue);
  });

  test('parses attempt detail with topic stats and review answers', () {
    final attempt = MockAttempt.fromJson({
      'id': 'attempt-1',
      'status': 'SUBMITTED',
      'score': 18,
      'totalPossibleScore': 20,
      'percentScore': 90,
      'durationSeconds': 1800,
      'answers': {'q1': 0, 'q2': 2},
      'topicStats': [
        {'topic': 'Algebra', 'total': 10, 'correct': 9, 'percent': 90},
      ],
      'remediationSuggestions': [
        {'topic': 'Geometry', 'percent': 40, 'questionCount': 5, 'correctCount': 2},
      ],
      'exam': {
        'id': 'exam-1',
        'title': 'Math mock',
        'slug': 'math-mock',
        'mode': 'MOCK',
        'durationMinutes': 60,
        'totalQuestions': 2,
        'questions': [
          {
            'id': 'q1',
            'questionText': '2 + 2 = ?',
            'options': ['4', '5'],
            'position': 1,
            'correctOptionIndex': 0,
            'explanation': 'Basic addition.',
          },
        ],
      },
    });

    expect(attempt.topicStats, hasLength(1));
    expect(attempt.topicStats.first.topic, 'Algebra');
    expect(attempt.remediationSuggestions.first.topic, 'Geometry');
    expect(attempt.answers['q1'], 0);
    expect(attempt.exam?.questions.first.correctOptionIndex, 0);
    expect(attempt.exam?.questions.first.explanation, 'Basic addition.');
  });

  test('parses exam detail metadata fields', () {
    final exam = MockExam.fromJson({
      'id': 'exam-1',
      'title': 'JAMB Physics 2024',
      'slug': 'jamb-physics-2024',
      'mode': 'PAST_PAPER',
      'durationMinutes': 60,
      'totalQuestions': 40,
      'totalMarks': 40,
      'difficulty': 'INTERMEDIATE',
      'instructions': 'Answer all questions.',
      'examYear': 2024,
      'accessState': 'LOCKED',
      'percentScore': 72,
      'examType': {'id': '1', 'slug': 'jamb', 'title': 'JAMB'},
      'subject': {'id': '2', 'name': 'Physics', 'slug': 'physics'},
    });

    expect(exam.difficulty, 'INTERMEDIATE');
    expect(exam.instructions, 'Answer all questions.');
    expect(exam.totalMarks, 40);
    expect(exam.displayTotalMarks, 40);
    expect(exam.examYear, 2024);
    expect(exam.isLocked, isTrue);
    expect(exam.isFreePractice, isFalse);
    expect(formatMockDifficulty(exam.difficulty), 'Intermediate');
  });

  test('persists exam session timer and review flags offline', () async {
    Hive.init('./.dart_tool/test_hive_exam_session');
    await Hive.openBox<Map>(OfflineStorage.sessionBoxName);
    await OfflineStorage.sessionBox.clear();

    final store = ExamSessionStore();
    final exam = MockExam(
      id: 'exam-1',
      title: 'Physics mock',
      slug: 'physics-mock',
      mode: 'MOCK',
      durationMinutes: 45,
      totalQuestions: 2,
      questions: const [
        MockQuestion(id: 'q1', questionText: 'Q1', options: ['A', 'B'], position: 1),
      ],
    );

    await store.saveSession(
      slug: 'physics-mock',
      attemptId: 'attempt-1',
      exam: exam,
      answers: const {'q1': 1},
      currentIndex: 0,
      startedAt: DateTime.parse('2026-01-01T10:00:00.000Z'),
      timeLeftSeconds: 1200,
      markedForReview: const {'q1': true},
    );

    final restored = store.getSessionForSlug('physics-mock');
    expect(restored?.timeLeftSeconds, 1200);
    expect(restored?.markedForReview['q1'], isTrue);
    expect(restored?.answers['q1'], 1);

    await Hive.close();
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
