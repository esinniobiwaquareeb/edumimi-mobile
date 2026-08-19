import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
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
          final isAuthRoute = path.contains('/auth/login') || path.contains('/auth/signup');
          if (!isAuthRoute) {
            await ref.read(authStorageProvider).clear();
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
}

ApiException _mapDioError(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String) {
    return ApiException(data['message'] as String, statusCode: error.response?.statusCode);
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return ApiException('Connection timed out. Check your network.');
  }
  if (error.type == DioExceptionType.connectionError) {
    return ApiException('Cannot reach the server. Check your connection.');
  }
  return ApiException('Request failed.', statusCode: error.response?.statusCode);
}
