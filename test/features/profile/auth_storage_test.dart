import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';

void main() {
  test('saveSession + loadSession + clearSession (in-memory storage)', () async {
    final storage = AuthStorage(_InMemorySecureStorage());
    await storage.saveSession(
      access: 'a', refresh: 'r', expiresAt: 1234567890,
    );
    final s = await storage.loadSession();
    expect(s?.access, 'a');
    expect(s?.refresh, 'r');
    expect(s?.expiresAt, 1234567890);
    await storage.clearSession();
    expect(await storage.loadSession(), isNull);
  });
}

class _InMemorySecureStorage implements SecureStorageLike {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}
