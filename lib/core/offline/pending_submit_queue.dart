import 'package:mock_mobile/core/offline/offline_storage.dart';

class PendingSubmit {
  const PendingSubmit({
    required this.id,
    required this.attemptId,
    required this.examSlug,
    required this.examTitle,
    required this.answers,
    required this.durationSeconds,
    required this.queuedAt,
  });

  factory PendingSubmit.fromMap(Map map) {
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

    return PendingSubmit(
      id: map['id']?.toString() ?? '',
      attemptId: map['attemptId']?.toString() ?? '',
      examSlug: map['examSlug']?.toString() ?? '',
      examTitle: map['examTitle']?.toString() ?? 'Practice',
      answers: answers,
      durationSeconds: map['durationSeconds'] is int
          ? map['durationSeconds'] as int
          : int.tryParse(map['durationSeconds']?.toString() ?? '') ?? 0,
      queuedAt: DateTime.tryParse(map['queuedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String attemptId;
  final String examSlug;
  final String examTitle;
  final Map<String, int> answers;
  final int durationSeconds;
  final DateTime queuedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attemptId': attemptId,
      'examSlug': examSlug,
      'examTitle': examTitle,
      'answers': answers,
      'durationSeconds': durationSeconds,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }
}

class PendingSubmitQueue {
  List<PendingSubmit> listPending() {
    return OfflineStorage.pendingBox.values
        .map(PendingSubmit.fromMap)
        .toList()
      ..sort((left, right) => left.queuedAt.compareTo(right.queuedAt));
  }

  int get count => OfflineStorage.pendingBox.length;

  Future<void> enqueue(PendingSubmit item) async {
    await OfflineStorage.pendingBox.put(item.id, item.toMap());
  }

  Future<void> remove(String id) async {
    await OfflineStorage.pendingBox.delete(id);
  }

  Future<void> clear() async {
    await OfflineStorage.pendingBox.clear();
  }
}
