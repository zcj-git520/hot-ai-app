import 'package:hot_ai_app/features/profile/domain/user.dart';

abstract class UserRepository {
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(
      String email, String password);
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(
      String email, String password, String nickname);
  Future<String> refresh(String refreshToken);
  Future<User> me();
  Future<void> registerPushToken(String token, String platform);
  Future<void> deletePushToken();
}
