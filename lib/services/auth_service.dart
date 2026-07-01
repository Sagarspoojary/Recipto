import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../core/routes/routes.dart'; // to access navigatorKey
import '../core/theme/theme.dart';
import '../widgets/glass_container.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '15580599771-vqp5kf2g3gtqdsnp1i0ri6pnifquth0g.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Future Agent',
      photoUrl: user.photoURL,
    );
  }

  Future<void> _createFirestoreProfile(User user, String name, String provider) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'uid': user.uid,
        'fullName': name,
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'authProvider': provider,
        'phoneNumber': '',
        'dateOfBirth': '',
        'gender': '',
        'country': '',
        'state': '',
        'city': '',
        'address': '',
        'language': 'en',
        'occupation': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
      });
    } else {
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<AppUser?> get onAuthStateChanged =>
      _auth.authStateChanges().map(_mapFirebaseUser);

  @override
  AppUser? get currentUser => _mapFirebaseUser(_auth.currentUser);

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _createFirestoreProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'Google User',
          'google',
        );
      }
      return _mapFirebaseUser(userCredential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential = await _auth.signInWithProvider(appleProvider);
      if (userCredential.user != null) {
        await _createFirestoreProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'Apple User',
          'apple',
        );
      }
      return _mapFirebaseUser(userCredential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithGitHub() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw Exception("Navigation context not available");
    }

    try {
      // 1. Request device authorization code
      final response = await http.post(
        Uri.parse('https://github.com/login/device/code'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': 'Ov23lihmxyu3lKb0kMt9',
          'scope': 'read:user user:email',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to get GitHub device code");
      }

      final data = json.decode(response.body);
      final String deviceCode = data['device_code'];
      final String userCode = data['user_code'];
      final String verificationUri = data['verification_uri'];
      final int interval = data['interval'] ?? 5;

      // 2. Show the dialog with user_code
      bool isCancelled = false;
      String? accessToken;

      if (!context.mounted) {
        throw Exception("Navigation context is no longer active");
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return GlassContainer(
            borderRadius: 24,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              title: const Text(
                'GitHub Activation',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please copy the code below and activate the app on GitHub:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      userCode,
                      style: const TextStyle(
                        color: ReceiptoTheme.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(verificationUri);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ReceiptoTheme.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Open GitHub Activation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          );
        },
      );

      // 3. Poll GitHub for access token
      while (!isCancelled && accessToken == null) {
        await Future.delayed(Duration(seconds: interval));

        final tokenResponse = await http.post(
          Uri.parse('https://github.com/login/oauth/access_token'),
          headers: {'Accept': 'application/json'},
          body: {
            'client_id': 'Ov23lihmxyu3lKb0kMt9',
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
        );

        if (tokenResponse.statusCode == 200) {
          final tokenData = json.decode(tokenResponse.body);
          if (tokenData['access_token'] != null) {
            accessToken = tokenData['access_token'];
            break;
          } else if (tokenData['error'] == 'authorization_pending') {
            // keep waiting
            continue;
          } else if (tokenData['error'] == 'expired_token' || tokenData['error'] == 'access_denied') {
            throw Exception(tokenData['error_description'] ?? "Authentication expired or denied");
          }
        }
      }

      // Close Dialog
      if (context.mounted && !isCancelled) {
        Navigator.of(context).pop();
      }

      if (isCancelled || accessToken == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // 4. Authenticate in Firebase with GitHub credential
      final AuthCredential credential = GithubAuthProvider.credential(accessToken);
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createFirestoreProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'GitHub User',
          'github',
        );
      }

      return _mapFirebaseUser(userCredential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword(String name, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
        final updatedUser = _auth.currentUser!;
        await _createFirestoreProfile(updatedUser, name, 'email');
        await sendEmailVerification();
      }
      return _mapFirebaseUser(userCredential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _createFirestoreProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'Email User',
          'email',
        );
      }
      return _mapFirebaseUser(userCredential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
