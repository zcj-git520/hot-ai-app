import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data['code'] is int) {
      final code = data['code'] as int;
      // 后端返回 code: 200 或 code: 0 都表示成功
      if (code != 0 && code != 200) {
        return handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: AppException(
            code: code,
            message: (data['message'] as String?) ?? '业务错误',
          ),
        ));
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppException) return handler.next(err);
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return handler.next(err);
    }
    final status = err.response?.statusCode ?? 0;
    return handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: AppException(
        code: status,
        message: err.message ?? '网络异常',
      ),
    ));
  }
}
