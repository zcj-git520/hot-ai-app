import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class _FakeRepo implements UserRepository {
  User? _u;
  bool shouldFail = false;
  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(String e, String p) async {
    if (shouldFail) throw Exception('boom');
    _u = User(id: '1', email: e, nickname: 'n');
    return (accessToken: 'a', refreshToken: 'r', expiresAt: 0, user: _u!);
  }
  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(String e, String p, String n) async => login(e, p);
  @override
  Future<String> refresh(String t) async => 'new';
  @override
  Future<User> me() async => _u!;
  @override
  Future<void> registerPushToken(String t, String p) async {}
  @override
  Future<void> deletePushToken() async {}
}

void main() {
  test('login 成功进入 authenticated', () async {
    final repo = _FakeRepo();
    final c = AuthController(repo);
    await c.login('a@b.com', 'pw');
    expect(c.state.status, AuthStatus.authenticated);
    expect(c.state.user?.email, 'a@b.com');
  });

  test('login 失败进入 unauthenticated + error', () async {
    final repo = _FakeRepo()..shouldFail = true;
    final c = AuthController(repo);
    await c.login('a@b.com', 'pw');
    expect(c.state.status, AuthStatus.unauthenticated);
    expect(c.state.error, contains('boom'));
  });
}
