import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  Session({required this.access, required this.refresh, required this.expiresAt});
  final String access;
  final String refresh;
  final int expiresAt;
  Map<String, dynamic> toJson() => {'a': access, 'r': refresh, 'e': expiresAt};
  factory Session.fromJson(Map<String, dynamic> j) => Session(
        access: j['a'] as String,
        refresh: j['r'] as String,
        expiresAt: j['e'] as int,
      );
}

abstract class AuthStorageLike {
  Future<void> saveSession({required String access, required String refresh, required int expiresAt});
  Future<Session?> loadSession();
  Future<void> clearSession();
}

abstract class SecureStorageLike {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureStorageLike {
  FlutterSecureStorageAdapter(this._s);
  final FlutterSecureStorage _s;

  @override
  Future<void> write({required String key, required String? value}) =>
      _s.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _s.read(key: key);

  @override
  Future<void> delete({required String key}) => _s.delete(key: key);
}

class AuthStorage implements AuthStorageLike {
  AuthStorage(SecureStorageLike storage) : _s = storage;
  final SecureStorageLike _s;
  static const _k = 'session';

  @override
  Future<void> saveSession({required String access, required String refresh, required int expiresAt}) async {
    await _s.write(key: _k, value: Session(access: access, refresh: refresh, expiresAt: expiresAt).toJson().toString());
  }

  @override
  Future<Session?> loadSession() async {
    final raw = await _s.read(key: _k);
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[{}]'), '');
    final map = <String, String>{};
    for (final part in cleaned.split(', ')) {
      final kv = part.split(': ');
      if (kv.length == 2) map[kv[0]] = kv[1];
    }
    return Session(
      access: map['a'] ?? '',
      refresh: map['r'] ?? '',
      expiresAt: int.tryParse(map['e'] ?? '') ?? 0,
    );
  }

  @override
  Future<void> clearSession() => _s.delete(key: _k);
}
