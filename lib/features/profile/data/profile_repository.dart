import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<MockUser> updateProfile({required String fullName, String? phone}) {
    return _dio.patchData(
      ApiPaths.me,
      data: {'fullName': fullName.trim(), 'phone': phone?.trim().isEmpty == true ? null : phone?.trim()},
      parser: (json) {
        final data = json as Map<String, dynamic>;
        return MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
      },
    );
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    return _dio.postData(
      ApiPaths.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      parser: (_) {},
    );
  }

  Future<void> setupTransactionPin({
    required String password,
    required String pin,
    required String confirmPin,
  }) {
    return _dio.postData(
      ApiPaths.transactionPin,
      data: {'password': password, 'pin': pin.trim(), 'confirmPin': confirmPin.trim()},
      parser: (_) {},
    );
  }

  Future<void> changeTransactionPin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) {
    return _dio.patchData(
      ApiPaths.transactionPin,
      data: {'currentPin': currentPin.trim(), 'newPin': newPin.trim(), 'confirmPin': confirmPin.trim()},
      parser: (_) {},
    );
  }

  Future<MockUser> fetchMe() {
    return _dio.getData(
      ApiPaths.me,
      parser: (json) => MockUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockInterests> savePreferences(Map<String, dynamic> payload) {
    return _dio.patchData(
      ApiPaths.preferences,
      data: payload,
      parser: (json) {
        final data = json as Map<String, dynamic>;
        return MockInterests.fromJson(data['interests'] as Map<String, dynamic>? ?? data);
      },
    );
  }

  Future<MockUser> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    try {
      final response = await _dio.post<dynamic>(ApiPaths.avatar, data: formData);
      final data = response.data as Map<String, dynamic>;
      return MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<MockUser> removeAvatar() {
    return _dio.deleteData(
      ApiPaths.avatar,
      parser: (json) {
        final data = json as Map<String, dynamic>;
        return MockUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
      },
    );
  }

  Future<void> resendVerification(String email) {
    return _dio.postData(
      ApiPaths.resendVerification,
      data: {'email': email},
      parser: (_) {},
    );
  }

  Future<ParentShareLink> fetchParentShareLink() {
    return _dio.getData(
      ApiPaths.parentShare,
      parser: (json) => ParentShareLink.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> applyReferralCode(String referralCode) {
    return _dio.postData(
      ApiPaths.referralApply,
      data: {'referralCode': referralCode.trim()},
      parser: (_) {},
    );
  }

  Future<void> updateReferralCode(String referralCode) {
    return _dio.patchData(
      ApiPaths.referralCode,
      data: {'referralCode': referralCode.trim()},
      parser: (_) {},
    );
  }

  Future<void> redeemBulkLicense(String code) {
    return _dio.postData(
      ApiPaths.bulkLicenseRedeem,
      data: {'code': code.trim()},
      parser: (_) {},
    );
  }
}

class ParentShareLink {
  const ParentShareLink({
    required this.token,
    required this.sharePath,
    required this.shareUrl,
  });

  factory ParentShareLink.fromJson(Map<String, dynamic> json) {
    return ParentShareLink(
      token: json['token']?.toString() ?? '',
      sharePath: json['sharePath']?.toString() ?? '',
      shareUrl: json['shareUrl']?.toString() ?? '',
    );
  }

  final String token;
  final String sharePath;
  final String shareUrl;
}

ApiException _mapDioError(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String) {
    return ApiException(data['message'] as String, statusCode: error.response?.statusCode);
  }
  return ApiException('Request failed.', statusCode: error.response?.statusCode);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});
