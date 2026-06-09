import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';

typedef OnUnauthorized = Future<bool> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, this.onUnauthorized});

  final TokenStorage storage;
  final OnUnauthorized? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['_noAuth'] == true) return handler.next(options);
    final token = await storage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
