import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getUserProfile(String uid) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('uid', uid)
        .maybeSingle();
        
    if (response != null) {
      return UserProfile.fromMap(response, uid);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  Future<String?> uploadProfileImage(String uid, String filePath) async {
    final file = File(filePath);
    final storageRef = _client.storage.from('profile_images');
    
    // Upload image file
    await storageRef.upload(
      '$uid/profile.jpg',
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    
    final downloadUrl = storageRef.getPublicUrl('$uid/profile.jpg');
    
    // Update the database profile with the new public URL
    await _client.from('profiles').update({
      'photo_url': downloadUrl,
    }).eq('uid', uid);
    
    return downloadUrl;
  }

  Future<void> removeProfileImage(String uid) async {
    try {
      await _client.storage.from('profile_images').remove(['$uid/profile.jpg']);
    } catch (_) {
      // Ignore storage errors if the file didn't exist
    }
    
    // Clear URL in profiles table
    await _client.from('profiles').update({
      'photo_url': null,
    }).eq('uid', uid);
  }
}
