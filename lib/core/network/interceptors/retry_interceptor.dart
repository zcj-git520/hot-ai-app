import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio, this.maxRetries = 1}) : _dio = dio;
  final Dio _dio;
  final int maxRetries;

  bool _isIdempotent(String method) => method == 'GET' || method == 'HEAD' || method == 'OPTIONS';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (!_isIdempotent(options.method)) return handler.next(err);
    options.extra['_retryCount'] ??= 0;
    if ((options.extra['_retryCount'] as int) >= maxRetries) return handler.next(err);
    if (err.type != DioExceptionType.connectionError &&
        err.type != DioExceptionType.connectionTimeout) {
      return handler.next(err);
    }
    options.extra['_retryCount'] = (options.extra['_retryCount'] as int) + 1;
    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) handler.next(e);
    }
  }
}
