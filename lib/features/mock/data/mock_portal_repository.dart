import 'dart:io';

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
      queryParameters: {'platform': Platform.isIOS ? 'ios' : 'android'},
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
        return json
            .whereType<Map<String, dynamic>>()
            .map(MockExamType.fromJson)
            .toList();
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
        if (examTypeSlug != null && examTypeSlug.isNotEmpty)
          'examTypeSlug': examTypeSlug,
        if (mode != null && mode.isNotEmpty) 'mode': mode,
        if (subjectSlug != null && subjectSlug.isNotEmpty)
          'subjectSlug': subjectSlug,
        if (paperYearFrom != null) 'paperYearFrom': paperYearFrom.toString(),
        if (paperYearTo != null) 'paperYearTo': paperYearTo.toString(),
        if (examYear != null) 'examYear': examYear.toString(),
      },
      parser: (json) {
        if (json is! List) {
          return <MockExam>[];
        }
        return json
            .whereType<Map<String, dynamic>>()
            .map(MockExam.fromJson)
            .toList();
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
        'platform': Platform.isIOS ? 'ios' : 'android',
        if (challengeToken != null && challengeToken.isNotEmpty)
          'challengeToken': challengeToken,
        if (adaptive) 'adaptive': true,
        if (focusTopics != null && focusTopics.isNotEmpty)
          'focusTopics': focusTopics,
        if (questionCount != null) 'questionCount': questionCount,
      },
      parser: (json) =>
          StartAttemptResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<GuestStartAttemptResponse> startGuestExam(String slug) {
    return _dio.postData(
      ApiPaths.startGuestExam(slug),
      data: {'sessionId': DateTime.now().millisecondsSinceEpoch.toString()},
      parser: (json) =>
          GuestStartAttemptResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<GuestAttemptResult> submitGuestAttempt({
    required String guestToken,
    required Map<String, int> answers,
    required int durationSeconds,
  }) {
    return _dio.postData(
      ApiPaths.submitGuestAttempt,
      data: {
        'guestToken': guestToken,
        'answers': answers,
        'durationSeconds': durationSeconds,
      },
      parser: (json) =>
          GuestAttemptResult.fromJson(json as Map<String, dynamic>),
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
        return json
            .whereType<Map<String, dynamic>>()
            .map(MockAttempt.fromJson)
            .toList();
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
      parser: (json) =>
          MockChallengeShare.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockStudyInsights> fetchStudyInsights() {
    return _dio.getData(
      ApiPaths.studyInsights,
      parser: (json) =>
          MockStudyInsights.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<LeaderboardResponse> fetchLeaderboard({
    required String period,
    String? examTypeSlug,
    int page = 1,
    int limit = 25,
  }) {
    return _dio.getData(
      ApiPaths.leaderboard,
      queryParameters: {
        'period': period,
        'page': '$page',
        'limit': '$limit',
        if (examTypeSlug != null && examTypeSlug.isNotEmpty)
          'examTypeSlug': examTypeSlug,
      },
      parser: (json) {
        if (json is! Map) {
          return const LeaderboardResponse(period: 'week', entries: []);
        }
        return LeaderboardResponse.fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<MockPublicChallenge> fetchPublicChallenge(String token) {
    return _dio.getData(
      ApiPaths.publicChallenge(token),
      parser: (json) =>
          MockPublicChallenge.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<JambSyllabusModule> fetchJambSyllabus() {
    return fetchExamSyllabus('jamb');
  }

  Future<JambSyllabusModule> fetchExamSyllabus(String examTypeSlug) {
    final path = switch (examTypeSlug.trim().toLowerCase()) {
      'waec' => ApiPaths.waecSyllabus,
      'neco' => ApiPaths.necoSyllabus,
      _ => ApiPaths.jambSyllabus,
    };
    return _dio.getData(
      path,
      parser: (json) =>
          JambSyllabusModule.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<PostUtmePackSummary>> fetchPostUtmePacks() {
    return _dio.getData(
      ApiPaths.postUtmePacks,
      parser: (json) {
        final data = json as Map<String, dynamic>;
        final packs = data['packs'];
        if (packs is! List) return <PostUtmePackSummary>[];
        return packs
            .whereType<Map<String, dynamic>>()
            .map(PostUtmePackSummary.fromJson)
            .toList();
      },
    );
  }

  Future<PostUtmePackDetail> fetchPostUtmePackDetail(String slug) {
    return _dio.getData(
      ApiPaths.postUtmePackDetail(slug),
      parser: (json) =>
          PostUtmePackDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ParentProgressView> fetchParentView(String token) {
    return _dio.getData(
      ApiPaths.publicParentView(token),
      parser: (json) =>
          ParentProgressView.fromJson(json as Map<String, dynamic>),
    );
  }
}

class GuestStartAttemptResponse {
  const GuestStartAttemptResponse({
    required this.guestToken,
    required this.exam,
  });

  factory GuestStartAttemptResponse.fromJson(Map<String, dynamic> json) {
    return GuestStartAttemptResponse(
      guestToken: json['guestToken']?.toString() ?? '',
      exam: MockExam.fromJson(json['exam'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String guestToken;
  final MockExam exam;
}

class GuestAttemptResult {
  const GuestAttemptResult({
    required this.examTitle,
    required this.score,
    required this.totalPossibleScore,
    required this.percentScore,
  });

  factory GuestAttemptResult.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    double asDouble(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    final exam = json['exam'] as Map<String, dynamic>?;
    return GuestAttemptResult(
      examTitle: exam?['title']?.toString() ?? 'Practice result',
      score: asInt(json['score']),
      totalPossibleScore: asInt(json['totalPossibleScore']),
      percentScore: asDouble(json['percentScore']),
    );
  }

  final String examTitle;
  final int score;
  final int totalPossibleScore;
  final double percentScore;
}

final mockPortalRepositoryProvider = Provider<MockPortalRepository>((ref) {
  return MockPortalRepository(ref.watch(dioProvider));
});

final examFeedProvider = FutureProvider.autoDispose<MockExamFeed>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamFeed();
});

final studyInsightsProvider = FutureProvider.autoDispose<MockStudyInsights>((
  ref,
) {
  return ref.watch(mockPortalRepositoryProvider).fetchStudyInsights();
});

final attemptsProvider = FutureProvider.autoDispose<List<MockAttempt>>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchAttempts();
});

final attemptDetailProvider = FutureProvider.autoDispose
    .family<MockAttempt, String>((ref, attemptId) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchAttemptDetail(attemptId);
    });

final examTypesProvider = FutureProvider.autoDispose<List<MockExamType>>((ref) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamTypes();
});

final examsCatalogProvider = FutureProvider.autoDispose
    .family<List<MockExam>, String?>((ref, examTypeSlug) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchExams(examTypeSlug: examTypeSlug);
    });

final leaderboardProvider = FutureProvider.autoDispose
    .family<
      LeaderboardResponse,
      ({String period, String? examTypeSlug, int page})
    >((ref, params) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchLeaderboard(
            period: params.period,
            examTypeSlug: params.examTypeSlug,
            page: params.page,
          );
    });

final examDetailProvider = FutureProvider.autoDispose.family<MockExam, String>((
  ref,
  slug,
) {
  return ref.watch(mockPortalRepositoryProvider).fetchExamDetail(slug);
});

final examTypeDetailProvider = FutureProvider.autoDispose
    .family<MockExamType, String>((ref, slug) {
      return ref.watch(mockPortalRepositoryProvider).fetchExamTypeDetail(slug);
    });

final publicChallengeProvider = FutureProvider.autoDispose
    .family<MockPublicChallenge, String>((ref, token) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchPublicChallenge(token);
    });

final jambSyllabusProvider = FutureProvider.autoDispose<JambSyllabusModule>((
  ref,
) {
  return ref.watch(mockPortalRepositoryProvider).fetchJambSyllabus();
});

final examSyllabusProvider = FutureProvider.autoDispose
    .family<JambSyllabusModule, String>((ref, examTypeSlug) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchExamSyllabus(examTypeSlug);
    });

final postUtmePacksProvider =
    FutureProvider.autoDispose<List<PostUtmePackSummary>>((ref) {
      return ref.watch(mockPortalRepositoryProvider).fetchPostUtmePacks();
    });

final postUtmePackDetailProvider = FutureProvider.autoDispose
    .family<PostUtmePackDetail, String>((ref, slug) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchPostUtmePackDetail(slug);
    });

final parentViewProvider = FutureProvider.autoDispose
    .family<ParentProgressView, String>((ref, token) {
      return ref.watch(mockPortalRepositoryProvider).fetchParentView(token);
    });
