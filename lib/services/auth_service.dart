import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    try {
      final githubProvider = GithubAuthProvider();
      githubProvider.setCustomParameters({
        'prompt': 'login',
      });
      final UserCredential userCredential = await _auth.signInWithProvider(githubProvider);
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
