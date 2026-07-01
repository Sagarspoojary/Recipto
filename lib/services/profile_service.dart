import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

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
    final storageRef = _supabase.storage.from('profile_images');

    // Upload to Supabase Storage
    await storageRef.upload(
      '$uid/profile.jpg',
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final downloadUrl = storageRef.getPublicUrl('$uid/profile.jpg');

    // Update the Firestore profile document with the new public URL from Supabase
    await _firestore.collection('users').doc(uid).update({
      'photoURL': downloadUrl,
    });

    return downloadUrl;
  }

  Future<void> removeProfileImage(String uid) async {
    try {
      await _supabase.storage.from('profile_images').remove(['$uid/profile.jpg']);
    } catch (_) {
      // Ignore storage errors if the file didn't exist
    }

    // Clear URL in Firestore
    await _firestore.collection('users').doc(uid).update({
      'photoURL': null,
    });
  }
}
