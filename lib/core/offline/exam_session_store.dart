import 'package:mock_mobile/core/offline/offline_storage.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class SavedExamSession {
  const SavedExamSession({
    required this.slug,
    required this.attemptId,
    required this.exam,
    required this.answers,
    required this.currentIndex,
    required this.startedAt,
    required this.updatedAt,
    required this.timeLeftSeconds,
    required this.markedForReview,
  });

  factory SavedExamSession.fromMap(Map map) {
    final answersRaw = map['answers'];
    final answers = <String, int>{};
    if (answersRaw is Map) {
      answersRaw.forEach((key, value) {
        final parsed = value is int ? value : int.tryParse(value.toString());
        if (parsed != null) {
          answers[key.toString()] = parsed;
        }
      });
    }

    final markedRaw = map['markedForReview'];
    final markedForReview = <String, bool>{};
    if (markedRaw is Map) {
      markedRaw.forEach((key, value) {
        markedForReview[key.toString()] = value == true;
      });
    }

    return SavedExamSession(
      slug: map['slug']?.toString() ?? '',
      attemptId: map['attemptId']?.toString() ?? '',
      exam: MockExam.fromJson(Map<String, dynamic>.from(map['exam'] as Map? ?? {})),
      answers: answers,
      currentIndex: map['currentIndex'] is int
          ? map['currentIndex'] as int
          : int.tryParse(map['currentIndex']?.toString() ?? '') ?? 0,
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      timeLeftSeconds: map['timeLeftSeconds'] is int
          ? map['timeLeftSeconds'] as int
          : int.tryParse(map['timeLeftSeconds']?.toString() ?? '') ??
              (map['timeLeft'] is int ? map['timeLeft'] as int : int.tryParse(map['timeLeft']?.toString() ?? '')) ??
              0,
      markedForReview: markedForReview,
    );
  }

  final String slug;
  final String attemptId;
  final MockExam exam;
  final Map<String, int> answers;
  final int currentIndex;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int timeLeftSeconds;
  final Map<String, bool> markedForReview;

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'attemptId': attemptId,
      'exam': exam.toJson(),
      'answers': answers,
      'currentIndex': currentIndex,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timeLeftSeconds': timeLeftSeconds,
      'markedForReview': markedForReview,
    };
  }
}

class ExamSessionStore {
  static const _activeKey = 'active';

  Future<void> saveSession({
    required String slug,
    required String attemptId,
    required MockExam exam,
    required Map<String, int> answers,
    required int currentIndex,
    required DateTime startedAt,
    required int timeLeftSeconds,
    required Map<String, bool> markedForReview,
  }) async {
    final session = SavedExamSession(
      slug: slug,
      attemptId: attemptId,
      exam: exam,
      answers: answers,
      currentIndex: currentIndex,
      startedAt: startedAt,
      updatedAt: DateTime.now(),
      timeLeftSeconds: timeLeftSeconds,
      markedForReview: markedForReview,
    );
    await OfflineStorage.sessionBox.put(_activeKey, session.toMap());
  }

  SavedExamSession? getActiveSession() {
    final raw = OfflineStorage.sessionBox.get(_activeKey);
    if (raw == null) {
      return null;
    }
    return SavedExamSession.fromMap(raw);
  }

  SavedExamSession? getSessionForSlug(String slug) {
    final session = getActiveSession();
    if (session == null || session.slug != slug) {
      return null;
    }
    return session;
  }

  Future<void> clearActiveSession() async {
    await OfflineStorage.sessionBox.delete(_activeKey);
  }
}
