import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final authServiceProviderProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final rememberMeProvider = StateProvider<bool>((ref) => false);

class AuthStateNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthStateNotifier(this._authService, this._ref) : super(const AsyncValue.data(null)) {
    _checkSavedSession();
    _init();
  }

  void _init() {
    _authService.onAuthStateChanged.listen(
      (user) => state = AsyncValue.data(user),
      onError: (err, stack) => state = AsyncValue.error(err, stack),
    );
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    _ref.read(rememberMeProvider.notifier).state = rememberMe;

    if (rememberMe) {
      final storage = _ref.read(secureStorageProvider);
      final email = await storage.read(key: 'auth_email');
      final pass = await storage.read(key: 'auth_password');
      if (email != null && pass != null) {
        signInEmail(email, pass);
      }
    }
  }

  Future<void> signInEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      final rememberMe = _ref.read(rememberMeProvider);
      if (rememberMe) {
        final storage = _ref.read(secureStorageProvider);
        await storage.write(key: 'auth_email', value: email);
        await storage.write(key: 'auth_password', value: password);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
      }
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUpEmail(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUpWithEmailAndPassword(name, email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordReset(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (_) {}
  }

  Future<bool> checkEmailVerified() async {
    try {
      return await _authService.isEmailVerified();
    } catch (_) {
      return false;
    }
  }

  Future<void> signInGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInApple() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithApple();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInGitHub() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGitHub();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      final storage = _ref.read(secureStorageProvider);
      await storage.delete(key: 'auth_email');
      await storage.delete(key: 'auth_password');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<AppUser?>>((ref) {
  final service = ref.watch(authServiceProviderProvider);
  return AuthStateNotifier(service, ref);
});
