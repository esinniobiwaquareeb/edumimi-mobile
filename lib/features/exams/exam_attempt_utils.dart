import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

List<MockAttempt> filterSubmittedAttemptsForExam(
  List<MockAttempt> attempts,
  MockExam exam,
) {
  final filtered = attempts
      .where(
        (attempt) =>
            attempt.isSubmitted &&
            (attempt.exam?.slug == exam.slug || attempt.exam?.id == exam.id),
      )
      .toList()
    ..sort((left, right) {
      final leftDate = left.submittedAt ?? '';
      final rightDate = right.submittedAt ?? '';
      return rightDate.compareTo(leftDate);
    });
  return filtered;
}
