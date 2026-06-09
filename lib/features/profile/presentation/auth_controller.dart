import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError('Override in main.dart');
});

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unauthenticated, this.user, this.error});
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState copyWith({AuthStatus? status, User? user, String? error, bool clearError = false}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());
  final UserRepository _repo;

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final r = await _repo.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: r.user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> register(String email, String password, String nickname) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final r = await _repo.register(email, password, nickname);
      state = state.copyWith(status: AuthStatus.authenticated, user: r.user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> logout() async {
    try { await _repo.deletePushToken(); } catch (_) {}
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(userRepositoryProvider));
});
