import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_engagement.dart';
import 'package:mock_mobile/shared/models/mock_package.dart';

class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<List<MockPackage>> fetchPackages({String? examTypeSlug}) {
    return _dio.getData(
      ApiPaths.packages,
      queryParameters: {
        if (examTypeSlug != null && examTypeSlug.isNotEmpty) 'examTypeSlug': examTypeSlug,
      },
      parser: (json) {
        if (json is! List) {
          return <MockPackage>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockPackage.fromJson).toList();
      },
    );
  }

  Future<List<MockPurchase>> fetchMyPurchases() {
    return _dio.getData(
      ApiPaths.myPurchases,
      parser: (json) {
        if (json is! List) {
          return <MockPurchase>[];
        }
        return json.whereType<Map<String, dynamic>>().map(MockPurchase.fromJson).toList();
      },
    );
  }

  Future<CheckoutResponse> initializeCheckout(String slug, {String? agentCode}) {
    return _dio.postData(
      ApiPaths.packageCheckout(slug),
      data: {
        if (agentCode != null && agentCode.isNotEmpty) 'agentCode': agentCode,
      },
      parser: (json) => CheckoutResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockPurchase> verifyPayment(String reference) {
    return _dio.getData(
      ApiPaths.verifyPayment,
      queryParameters: {'reference': reference},
      parser: (json) => MockPurchase.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MockEngagement> fetchEngagement() {
    return _dio.getData(
      ApiPaths.engagement,
      parser: (json) => MockEngagement.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> registerFcmToken({required String token, required String platform}) {
    return _dio.postData(
      ApiPaths.fcmRegister,
      data: {'token': token, 'platform': platform},
      parser: (_) {},
    );
  }

  Future<void> unregisterFcmToken(String token) {
    return _dio.deleteData(
      ApiPaths.fcmRegister,
      data: {'token': token},
      parser: (_) {},
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

final packagesProvider = FutureProvider.autoDispose<List<MockPackage>>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchPackages();
});

final myPurchasesProvider = FutureProvider.autoDispose<List<MockPurchase>>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchMyPurchases();
});

final engagementProvider = FutureProvider.autoDispose<MockEngagement>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchEngagement();
});

bool hasActivePackageSlug(List<MockPurchase> purchases, String slug) {
  return purchases.any((purchase) => purchase.package?.slug == slug && purchase.isActive);
}

bool hasPendingPackageSlug(List<MockPurchase> purchases, String slug) {
  return purchases.any((purchase) => purchase.package?.slug == slug && purchase.isPending);
}
