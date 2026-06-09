import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> writeAccess(String token);
  Future<void> writeRefresh(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  @override
  Future<String?> readAccess() => _storage.read(key: _kAccess);
  @override
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);
  @override
  Future<void> writeAccess(String t) => _storage.write(key: _kAccess, value: t);
  @override
  Future<void> writeRefresh(String t) => _storage.write(key: _kRefresh, value: t);
  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
