import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Mock-Client': 'mobile',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(authStorageProvider).readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          final isAuthRoute = path.contains('/auth/login') ||
              path.contains('/auth/signup') ||
              path.contains('/auth/forgot-password') ||
              path.contains('/auth/reset-password') ||
              path.contains('/auth/verify-email');
          final isSessionValidation = path.endsWith('/me') || path == '/me';
          if (!isAuthRoute && !isSessionValidation) {
            await ref.read(authControllerProvider.notifier).logout(localOnly: true);
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

extension DioResponseX on Dio {
  Future<T> getData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await get<dynamic>(path, queryParameters: queryParameters);
      return parser(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<T> postData<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await post<dynamic>(path, data: data);
      return parser(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<T> patchData<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await patch<dynamic>(path, data: data);
      return parser(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<T> deleteData<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await delete<dynamic>(path, data: data);
      return parser(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }
}

ApiException _mapDioError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return ApiException(message, statusCode: error.response?.statusCode);
    }
    if (message is List && message.isNotEmpty) {
      return ApiException(message.first.toString(), statusCode: error.response?.statusCode);
    }
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return ApiException('Connection timed out. Check your network.');
  }
  if (error.type == DioExceptionType.connectionError) {
    return ApiException(
      'Cannot reach the server at ${AppConfig.apiBaseUrl}. '
      'Check your connection or rebuild with --dart-define=MOCK_API_URL=...',
    );
  }
  final statusCode = error.response?.statusCode;
  if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
    return ApiException(
      'The server is temporarily unavailable ($statusCode). Try again in a few minutes.',
      statusCode: statusCode,
    );
  }
  if (statusCode != null && statusCode >= 500) {
    return ApiException('Server error ($statusCode). Try again later.', statusCode: statusCode);
  }
  return ApiException('Request failed.', statusCode: statusCode);
}
