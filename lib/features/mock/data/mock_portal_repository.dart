import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';
import 'package:mock_mobile/shared/models/mock_growth.dart';

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

  Future<List<MockExam>> fetchExams({
    String? examTypeSlug,
    String? mode,
    String? subjectSlug,
    int? paperYearFrom,
    int? paperYearTo,
    int? examYear,
  }) {
    return _dio.getData(
      ApiPaths.exams,
      queryParameters: {
        if (examTypeSlug != null && examTypeSlug.isNotEmpty) 'examTypeSlug': examTypeSlug,
        if (mode != null && mode.isNotEmpty) 'mode': mode,
        if (subjectSlug != null && subjectSlug.isNotEmpty) 'subjectSlug': subjectSlug,
        if (paperYearFrom != null) 'paperYearFrom': paperYearFrom.toString(),
        if (paperYearTo != null) 'paperYearTo': paperYearTo.toString(),
        if (examYear != null) 'examYear': examYear.toString(),
      },
      parser: (json) {
        if (json is! List) {
          return <MockExam>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockExam.fromJson).toList();
      },
    );
  }

  Future<MockExamType> fetchExamTypeDetail(String slug) {
    return _dio.getData(
      ApiPaths.examTypeDetail(slug),
      parser: (json) => MockExamType.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockExam> fetchExamDetail(String slug) {
    return _dio.getData(
      ApiPaths.examDetail(slug),
      parser: (json) => MockExam.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StartAttemptResponse> startExam(
    String slug, {
    required String sessionId,
    String? challengeToken,
    bool adaptive = false,
    List<String>? focusTopics,
    int? questionCount,
  }) {
    return _dio.postData(
      ApiPaths.startExam(slug),
      data: {
        'sessionId': sessionId,
        if (challengeToken != null && challengeToken.isNotEmpty) 'challengeToken': challengeToken,
        if (adaptive) 'adaptive': true,
        if (focusTopics != null && focusTopics.isNotEmpty) 'focusTopics': focusTopics,
        if (questionCount != null) 'questionCount': questionCount,
      },
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

  Future<MockAttempt> fetchAttemptDetail(String attemptId) {
    return _dio.getData(
      ApiPaths.attemptDetail(attemptId),
      parser: (json) => MockAttempt.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockChallengeShare> fetchChallengeShare(String attemptId) {
    return _dio.getData(
      ApiPaths.attemptChallenge(attemptId),
      parser: (json) => MockChallengeShare.fromJson(json as Map<String, dynamic>),
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

  Future<MockPublicChallenge> fetchPublicChallenge(String token) {
    return _dio.getData(
      ApiPaths.publicChallenge(token),
      parser: (json) => MockPublicChallenge.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<JambSyllabusModule> fetchJambSyllabus() {
    return _dio.getData(
      ApiPaths.jambSyllabus,
      parser: (json) => JambSyllabusModule.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<PostUtmePackSummary>> fetchPostUtmePacks() {
    return _dio.getData(
      ApiPaths.postUtmePacks,
      parser: (json) {
        final data = json as Map<String, dynamic>;
        final packs = data['packs'];
        if (packs is! List) return <PostUtmePackSummary>[];
        return packs.whereType<Map<String, dynamic>>().map(PostUtmePackSummary.fromJson).toList();
      },
    );
  }

  Future<PostUtmePackDetail> fetchPostUtmePackDetail(String slug) {
    return _dio.getData(
      ApiPaths.postUtmePackDetail(slug),
      parser: (json) => PostUtmePackDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ParentProgressView> fetchParentView(String token) {
    return _dio.getData(
      ApiPaths.publicParentView(token),
      parser: (json) => ParentProgressView.fromJson(json as Map<String, dynamic>),
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

final attemptDetailProvider = FutureProvider.autoDispose.family<MockAttempt, String>((ref, attemptId) {
  return ref.watch(mockPortalRepositoryProvider).fetchAttemptDetail(attemptId);
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

final examTypeDetailProvider = FutureProvider.autoDispose.family<MockExamType, String>((ref, slug) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamTypeDetail(slug);
});

final publicChallengeProvider = FutureProvider.autoDispose.family<MockPublicChallenge, String>((ref, token) {
  return ref.watch(mockPortalRepositoryProvider).fetchPublicChallenge(token);
});

final jambSyllabusProvider = FutureProvider.autoDispose<JambSyllabusModule>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchJambSyllabus();
});

final postUtmePacksProvider = FutureProvider.autoDispose<List<PostUtmePackSummary>>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchPostUtmePacks();
});

final postUtmePackDetailProvider = FutureProvider.autoDispose.family<PostUtmePackDetail, String>((ref, slug) {
  return ref.watch(mockPortalRepositoryProvider).fetchPostUtmePackDetail(slug);
});

final parentViewProvider = FutureProvider.autoDispose.family<ParentProgressView, String>((ref, token) {
  return ref.watch(mockPortalRepositoryProvider).fetchParentView(token);
});
