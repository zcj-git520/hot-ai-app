import 'package:hot_ai_app/core/error/app_exception.dart';

class ApiResponse<T> {
  ApiResponse({required this.code, required this.message, this.data});

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) decoder,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: json['data'] == null ? null : decoder(json['data']),
    );
  }

  final int code;
  final String message;
  final T? data;

  T unwrap() {
    if (code != 0) {
      throw AppException(code: code, message: message);
    }
    if (data == null) {
      throw AppException(code: -1, message: '响应 data 为空');
    }
    return data as T;
  }
}
