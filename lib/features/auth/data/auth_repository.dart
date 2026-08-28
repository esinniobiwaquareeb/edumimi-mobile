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
    if (token == null || token.isEmpty) {
      return null;
    }
    final user = await _storage.readUser();
    if (user == null) {
      return AuthSession(
        token: token,
        user: const MockUser(id: '', email: '', role: 'MOCK_CUSTOMER'),
      );
    }
    return AuthSession(token: token, user: user);
  }

  Future<void> persistSession({
    required String token,
    required MockUser user,
  }) => _storage.saveSession(token: token, user: user);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
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

  Future<MockSignupResult> signup({
    required String fullName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final data = await _dio.postData<Map<String, dynamic>>(
      ApiPaths.signup,
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referralCode': referralCode.trim().toUpperCase(),
      },
      parser: (json) => json as Map<String, dynamic>,
    );

    return MockSignupResult(
      requiresVerification: data['requiresVerification'] == true,
      message:
          data['message']?.toString() ??
          'Account created. Check your email to verify it.',
    );
  }

  Future<MockUser> fetchMe() async {
    return _dio.getData(
      ApiPaths.me,
      parser: (json) => MockUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> clearSession() => _storage.clear();

  Future<void> forgotPassword({required String email}) {
    return _dio.postData(
      ApiPaths.forgotPassword,
      data: {'email': email.trim()},
      parser: (_) {},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _dio.postData(
      ApiPaths.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
      parser: (_) {},
    );
  }

  Future<AuthSession> verifyEmail({required String token}) async {
    final data = await _dio.postData<Map<String, dynamic>>(
      ApiPaths.verifyEmail,
      data: {'token': token},
      parser: (json) => json as Map<String, dynamic>,
    );
    final accessToken = data['access_token']?.toString() ?? '';
    final user = MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final session = AuthSession(token: accessToken, user: user);
    if (accessToken.isNotEmpty) {
      await _storage.saveSession(token: accessToken, user: user);
    }
    return session;
  }
}

class MockSignupResult {
  const MockSignupResult({
    required this.requiresVerification,
    required this.message,
  });

  final bool requiresVerification;
  final String message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(authStorageProvider));
});
