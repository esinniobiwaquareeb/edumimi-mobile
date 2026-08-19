class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  factory ApiException.fromDio(Object error) {
    if (error is ApiException) {
      return error;
    }
    return ApiException('Something went wrong. Try again.');
  }
}
