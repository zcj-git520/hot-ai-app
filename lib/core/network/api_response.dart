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
    // 后端返回 code: 200 或 code: 0 都表示成功
    if (code != 0 && code != 200) {
      throw AppException(code: code, message: message);
    }
    if (data == null) {
      throw AppException(code: -1, message: '响应 data 为空');
    }
    return data as T;
  }
}
