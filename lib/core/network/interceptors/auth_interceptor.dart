import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';

typedef OnUnauthorized = Future<bool> Function();

class _AuthState {
  bool refreshing = false;
  Completer<bool>? inFlight;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, this.onUnauthorized, Dio? dio}) : _dio = dio;

  final TokenStorage storage;
  final OnUnauthorized? onUnauthorized;
  final Dio? _dio;

  static final _state = _AuthState();
  static Completer<bool>? get _inFlight => _state.inFlight;
  static set _inFlight(Completer<bool>? c) => _state.inFlight = c;

  static void resetState() {
    _state.refreshing = false;
    _state.inFlight = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['_noAuth'] == true) return handler.next(options);
    final token = await storage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) return handler.next(err);
    if (err.requestOptions.extra['_retried'] == true) return handler.next(err);
    err.requestOptions.extra['_retried'] = true;

    final completer = _inFlight;
    if (completer != null) {
      final ok = await completer.future;
      if (!ok) return handler.next(err);
      return _retry(err, handler);
    }
    final c = Completer<bool>();
    _inFlight = c;
    bool ok = false;
    try {
      ok = await (onUnauthorized?.call() ?? Future.value(false));
    } catch (_) {
      ok = false;
    }
    c.complete(ok);
    _inFlight = null;
    if (!ok) return handler.next(err);
    _retry(err, handler);
  }

  void _retry(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final token = await storage.readAccess();
      err.requestOptions.headers['Authorization'] = token == null ? '' : 'Bearer $token';
      final dio = _dio ?? Dio();
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) handler.next(e);
    }
  }
}
