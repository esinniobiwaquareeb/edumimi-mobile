import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final AuthStorage _storage;

  Future<AuthSession?> readStoredSession() async {
    final token = await _storage.readToken();
    final user = await _storage.readUser();
    if (token == null || user == null) {
      return null;
    }
    return AuthSession(token: token, user: user);
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final data = await _dio.postData<Map<String, dynamic>>(
      ApiPaths.login,
      data: {'email': email.trim(), 'password': password},
      parser: (json) => json as Map<String, dynamic>,
    );

    final token = data['access_token']?.toString() ?? '';
    final user = MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final session = AuthSession(token: token, user: user);
    await _storage.saveSession(token: token, user: user);
    return session;
  }

  Future<AuthSession> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _dio.postData<Map<String, dynamic>>(
      ApiPaths.signup,
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      },
      parser: (json) => json as Map<String, dynamic>,
    );

    final token = data['access_token']?.toString() ?? '';
    final user = MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final session = AuthSession(token: token, user: user);
    await _storage.saveSession(token: token, user: user);
    return session;
  }

  Future<MockUser> fetchMe() async {
    return _dio.getData(ApiPaths.me, parser: (json) => MockUser.fromJson(json as Map<String, dynamic>));
  }

  Future<void> clearSession() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(authStorageProvider));
});
