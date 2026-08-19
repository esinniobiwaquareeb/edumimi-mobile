import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'mock_token';
  static const _userKey = 'mock_user';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<MockUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return MockUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession({required String token, required MockUser user}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
