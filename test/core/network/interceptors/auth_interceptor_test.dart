import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  String? access;
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> writeAccess(String t) async => access = t;
  @override
  Future<void> writeRefresh(String t) async {}
  @override
  Future<void> clear() async => access = null;
}

void main() {
  test('请求自动加 Authorization header', () async {
    final storage = _FakeTokenStorage()..access = 'token-abc';
    final dio = Dio()..interceptors.add(AuthInterceptor(storage: storage));
    String? captured;
    dio.httpClientAdapter = _CapturingAdapter((headers) => captured = headers['Authorization'] as String?);
    await dio.get('/x');
    expect(captured, 'Bearer token-abc');
  });

  test('无 token 时不加 header', () async {
    final storage = _FakeTokenStorage();
    final dio = Dio()..interceptors.add(AuthInterceptor(storage: storage));
    String? captured;
    dio.httpClientAdapter = _CapturingAdapter((headers) => captured = headers['Authorization'] as String?);
    await dio.get('/x');
    expect(captured, isNull);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.onHeaders);
  final void Function(Map<String, dynamic>) onHeaders;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? s, Future<void>? c) async {
    onHeaders(options.headers);
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
