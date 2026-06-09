import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/data/user_repository_impl.dart';

void main() {
  test('login 调 /auth/login 并保存 session', () async {
    final storage = AuthStorageForTest();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    final repo = UserRepositoryImpl(dio: dio, storage: storage);
    final r = await repo.login('a@b.com', 'pw');
    expect(r.accessToken, 'acc-1');
    expect(r.user.email, 'a@b.com');
    expect(storage.saved, isNotNull);
  });
}

class AuthStorageForTest implements AuthStorageLike {
  Session? saved;
  @override
  Future<void> saveSession({required String access, required String refresh, required int expiresAt}) async {
    saved = Session(access: access, refresh: refresh, expiresAt: expiresAt);
  }
  @override
  Future<Session?> loadSession() async => saved;
  @override
  Future<void> clearSession() async => saved = null;
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    final body = o.path == '/auth/login'
        ? '{"code":0,"data":{"accessToken":"acc-1","refreshToken":"ref-1","expiresAt":9999999999,"user":{"id":"u1","email":"a@b.com","nickname":"n"}},"message":"ok"}'
        : '{"code":0,"data":{},"message":"ok"}';
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
