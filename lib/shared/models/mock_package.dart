import 'package:equatable/equatable.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class MockPackage extends Equatable {
  const MockPackage({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.currencyCode,
    required this.accessDurationDays,
    this.description,
    this.compareAtPrice,
    this.maxAttempts,
    this.features = const [],
    this.isFeatured = false,
    this.examType,
  });

  factory MockPackage.fromJson(Map<String, dynamic> json) {
    final features = json['features'];
    return MockPackage(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Package',
      slug: json['slug']?.toString() ?? '',
      price: _asDouble(json['price']),
      compareAtPrice: json['compareAtPrice'] == null ? null : _asDouble(json['compareAtPrice']),
      currencyCode: json['currencyCode']?.toString() ?? 'NGN',
      accessDurationDays: _asInt(json['accessDurationDays']),
      maxAttempts: json['maxAttempts'] == null ? null : _asInt(json['maxAttempts']),
      description: json['description']?.toString(),
      isFeatured: json['isFeatured'] == true,
      features: features is List ? features.map((item) => item.toString()).toList() : const [],
      examType: json['examType'] is Map<String, dynamic>
          ? MockExamType.fromJson(json['examType'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String title;
  final String slug;
  final double price;
  final double? compareAtPrice;
  final String currencyCode;
  final int accessDurationDays;
  final int? maxAttempts;
  final String? description;
  final bool isFeatured;
  final List<String> features;
  final MockExamType? examType;

  @override
  List<Object?> get props => [id, slug, title, price];
}

class MockPurchase extends Equatable {
  const MockPurchase({
    required this.id,
    required this.status,
    this.paymentReference,
    this.accessStartsAt,
    this.accessEndsAt,
    this.amountPaid,
    this.currencyCode,
    this.package,
  });

  factory MockPurchase.fromJson(Map<String, dynamic> json) {
    return MockPurchase(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paymentReference: json['paymentReference']?.toString(),
      accessStartsAt: json['accessStartsAt']?.toString(),
      accessEndsAt: json['accessEndsAt']?.toString(),
      amountPaid: json['amountPaid'] == null ? null : _asDouble(json['amountPaid']),
      currencyCode: json['currencyCode']?.toString(),
      package: json['package'] is Map<String, dynamic>
          ? MockPackage.fromJson(json['package'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String status;
  final String? paymentReference;
  final String? accessStartsAt;
  final String? accessEndsAt;
  final double? amountPaid;
  final String? currencyCode;
  final MockPackage? package;

  bool get isSuccessful => status == 'SUCCESSFUL';
  bool get isPending => status == 'PENDING';

  bool get isActive {
    if (!isSuccessful || accessEndsAt == null) {
      return false;
    }
    final endsAt = DateTime.tryParse(accessEndsAt!);
    return endsAt != null && endsAt.isAfter(DateTime.now());
  }

  @override
  List<Object?> get props => [id, status, paymentReference];
}

class CheckoutResponse extends Equatable {
  const CheckoutResponse({
    required this.purchaseId,
    required this.paymentReference,
    this.authorizationUrl,
    this.accessCode,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      purchaseId: json['purchaseId']?.toString() ?? '',
      paymentReference: json['paymentReference']?.toString() ?? '',
      authorizationUrl: json['authorizationUrl']?.toString(),
      accessCode: json['accessCode']?.toString(),
    );
  }

  final String purchaseId;
  final String paymentReference;
  final String? authorizationUrl;
  final String? accessCode;

  @override
  List<Object?> get props => [purchaseId, paymentReference];
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
