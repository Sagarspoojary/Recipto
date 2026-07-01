import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<String?> uploadProfileImage(String uid, String filePath) async {
    final file = File(filePath);
    final ref = _storage.ref().child('profile_images/$uid/profile.jpg');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    // Update the Firestore profile document with the new download url
    await _firestore.collection('users').doc(uid).update({
      'photoURL': downloadUrl,
    });
    
    return downloadUrl;
  }

  Future<void> removeProfileImage(String uid) async {
    final ref = _storage.ref().child('profile_images/$uid/profile.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // Ignore storage errors if the file didn't exist
    }
    
    // Clear url in Firestore
    await _firestore.collection('users').doc(uid).update({
      'photoURL': null,
    });
  }
}
