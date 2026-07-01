import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

abstract class AuthService {
  Stream<AppUser?> get onAuthStateChanged;
  Future<AppUser?> signInWithGoogle();
  Future<AppUser?> signInWithApple();
  Future<AppUser?> signInWithGitHub();
  Future<AppUser?> signUpWithEmailAndPassword(String name, String email, String password);
  Future<AppUser?> signInWithEmailAndPassword(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> signOut();
  AppUser? get currentUser;
}

class FirebaseAuthService implements AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  AppUser? _mapSupabaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['displayName']?.toString() ??
          user.userMetadata?['full_name']?.toString() ??
          'Future Agent',
      photoUrl: user.userMetadata?['avatar_url']?.toString(),
    );
  }

  Future<void> _createSupabaseProfile(User user, String name, String provider) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('uid', user.id)
          .maybeSingle();

      if (response == null) {
        await _client.from('profiles').insert({
          'uid': user.id,
          'full_name': name,
          'email': user.email ?? '',
          'photo_url': user.userMetadata?['avatar_url']?.toString(),
          'auth_provider': provider,
          'phone_number': '',
          'date_of_birth': '',
          'gender': '',
          'country': '',
          'state': '',
          'city': '',
          'address': '',
          'language': 'en',
          'occupation': '',
        });
      } else {
        await _client.from('profiles').update({
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('uid', user.id);
      }
    } catch (e) {
      print('Profile sync error: $e');
    }
  }

  @override
  Stream<AppUser?> get onAuthStateChanged =>
      _client.auth.onAuthStateChange.map((data) => _mapSupabaseUser(data.session?.user));

  @override
  AppUser? get currentUser => _mapSupabaseUser(_client.auth.currentUser);

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      final user = _client.auth.currentUser;
      if (user != null) {
        await _createSupabaseProfile(
          user,
          user.userMetadata?['full_name']?.toString() ?? 'Google User',
          'google',
        );
      }
      return _mapSupabaseUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.apple);
      final user = _client.auth.currentUser;
      if (user != null) {
        await _createSupabaseProfile(
          user,
          user.userMetadata?['full_name']?.toString() ?? 'Apple User',
          'apple',
        );
      }
      return _mapSupabaseUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithGitHub() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.github);
      final user = _client.auth.currentUser;
      if (user != null) {
        await _createSupabaseProfile(
          user,
          user.userMetadata?['full_name']?.toString() ?? 'GitHub User',
          'github',
        );
      }
      return _mapSupabaseUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword(String name, String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'displayName': name},
      );
      final user = response.user;
      if (user != null) {
        await _createSupabaseProfile(user, name, 'email');
      }
      return _mapSupabaseUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await _createSupabaseProfile(
          user,
          user.userMetadata?['displayName']?.toString() ?? 'Email User',
          'email',
        );
      }
      return _mapSupabaseUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    // Supabase handles email verification flow dynamically via signup setting redirects
  }

  @override
  Future<bool> isEmailVerified() async {
    return _client.auth.currentUser?.emailConfirmedAt != null;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
