import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/services/user_service.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userService = ref.watch(userServiceProvider);

  return authService.authStateChanges.map((user) {
    if (user != null) {
      userService.saveUserData(user);
    }
    return user;
  });
});

final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(ref.watch(authServiceProvider));
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  LoginController(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
