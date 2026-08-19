import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class MockPortalRepository {
  MockPortalRepository(this._dio);

  final Dio _dio;

  Future<MockExamFeed> fetchExamFeed() {
    return _dio.getData(
      ApiPaths.examFeed,
      parser: (json) => MockExamFeed.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<MockExamType>> fetchExamTypes() {
    return _dio.getData(
      ApiPaths.examTypes,
      parser: (json) {
        if (json is! List) {
          return <MockExamType>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockExamType.fromJson).toList();
      },
    );
  }

  Future<List<MockExam>> fetchExams({String? examTypeSlug, String? mode}) {
    return _dio.getData(
      ApiPaths.exams,
      queryParameters: {
        if (examTypeSlug != null && examTypeSlug.isNotEmpty) 'examTypeSlug': examTypeSlug,
        if (mode != null && mode.isNotEmpty) 'mode': mode,
      },
      parser: (json) {
        if (json is! List) {
          return <MockExam>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockExam.fromJson).toList();
      },
    );
  }

  Future<MockExam> fetchExamDetail(String slug) {
    return _dio.getData(
      ApiPaths.examDetail(slug),
      parser: (json) => MockExam.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StartAttemptResponse> startExam(String slug, {required String sessionId}) {
    return _dio.postData(
      ApiPaths.startExam(slug),
      data: {'sessionId': sessionId},
      parser: (json) => StartAttemptResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockAttempt> submitAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
    required int durationSeconds,
  }) {
    return _dio.postData(
      ApiPaths.submitAttempt(attemptId),
      data: {'answers': answers, 'durationSeconds': durationSeconds},
      parser: (json) => MockAttempt.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<MockAttempt>> fetchAttempts() {
    return _dio.getData(
      ApiPaths.attempts,
      parser: (json) {
        if (json is! List) {
          return <MockAttempt>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockAttempt.fromJson).toList();
      },
    );
  }

  Future<MockStudyInsights> fetchStudyInsights() {
    return _dio.getData(
      ApiPaths.studyInsights,
      parser: (json) => MockStudyInsights.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<LeaderboardResponse> fetchLeaderboard({
    required String period,
    String? examTypeSlug,
  }) {
    return _dio.getData(
      ApiPaths.leaderboard,
      queryParameters: {
        'period': period,
        'limit': '30',
        if (examTypeSlug != null && examTypeSlug.isNotEmpty) 'examTypeSlug': examTypeSlug,
      },
      parser: (json) => LeaderboardResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

final mockPortalRepositoryProvider = Provider<MockPortalRepository>((ref) {
  return MockPortalRepository(ref.watch(dioProvider));
});

final examFeedProvider = FutureProvider.autoDispose<MockExamFeed>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamFeed();
});

final studyInsightsProvider = FutureProvider.autoDispose<MockStudyInsights>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchStudyInsights();
});

final attemptsProvider = FutureProvider.autoDispose<List<MockAttempt>>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchAttempts();
});

final examTypesProvider = FutureProvider.autoDispose<List<MockExamType>>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamTypes();
});

final examsCatalogProvider = FutureProvider.autoDispose.family<List<MockExam>, String?>((ref, examTypeSlug) {
  return ref.watch(mockPortalRepositoryProvider).fetchExams(examTypeSlug: examTypeSlug);
});

final leaderboardProvider = FutureProvider.autoDispose
    .family<LeaderboardResponse, ({String period, String? examTypeSlug})>((ref, params) {
  return ref.watch(mockPortalRepositoryProvider).fetchLeaderboard(
        period: params.period,
        examTypeSlug: params.examTypeSlug,
      );
});

final examDetailProvider = FutureProvider.autoDispose.family<MockExam, String>((ref, slug) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamDetail(slug);
});
