import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required this.dio, required this.storage});
  final Dio dio;
  final AuthStorageLike storage;

  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(
      String email, String password) async {
    final resp = await dio.post('/auth/login', data: {'email': email, 'password': password});
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
        resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final r = _parseAuth(data);
    await storage.saveSession(access: r.accessToken, refresh: r.refreshToken, expiresAt: r.expiresAt);
    return r;
  }

  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(
      String email, String password, String nickname) async {
    final resp = await dio.post('/auth/register', data: {'email': email, 'password': password, 'nickname': nickname});
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
        resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final r = _parseAuth(data);
    await storage.saveSession(access: r.accessToken, refresh: r.refreshToken, expiresAt: r.expiresAt);
    return r;
  }

  @override
  Future<String> refresh(String refreshToken) async {
    final resp = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken},
        options: Options(extra: {'_noAuth': true}));
    final data = ApiResponse.fromJson<String>(
        resp.data as Map<String, dynamic>, (j) => j as String).unwrap();
    return data;
  }

  @override
  Future<User> me() async {
    final resp = await dio.get('/user/me');
    final data = ApiResponse.fromJson<User>(
        resp.data as Map<String, dynamic>, (j) => User.fromJson(j as Map<String, dynamic>)).unwrap();
    return data;
  }

  @override
  Future<void> registerPushToken(String token, String platform) async {
    await dio.post('/user/push-token', data: {'token': token, 'platform': platform});
  }

  @override
  Future<void> deletePushToken() async {
    await dio.delete('/user/push-token');
  }

  ({String accessToken, String refreshToken, int expiresAt, User user}) _parseAuth(Map<String, dynamic> d) {
    return (
      accessToken: d['accessToken'] as String,
      refreshToken: d['refreshToken'] as String,
      expiresAt: d['expiresAt'] as int,
      user: User.fromJson(d['user'] as Map<String, dynamic>),
    );
  }
}
