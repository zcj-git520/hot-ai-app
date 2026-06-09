class AppException implements Exception {
  AppException({
    required this.code,
    required this.message,
    this.extra = const {},
  });

  final int code;
  final String message;
  final Map<String, dynamic> extra;

  @override
  String toString() => 'AppException($code): $message';
}
