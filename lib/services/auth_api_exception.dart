class AuthApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AuthApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}