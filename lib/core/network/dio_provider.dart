import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost/api',
);

Dio buildDio({String? baseUrl, List<Interceptor> interceptors = const []}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? kApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.addAll(interceptors);
  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  // interceptors 稍后注册
  return buildDio();
});
