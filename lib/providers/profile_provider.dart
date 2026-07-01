import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _service;
  final Ref _ref;

  ProfileNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _ref.listen(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            loadProfile(user.uid);
          } else {
            state = const AsyncValue.data(null);
          }
        },
        loading: () => state = const AsyncValue.loading(),
        error: (err, stack) => state = AsyncValue.error(err, stack),
      );
    }, fireImmediately: true);
  }

  Future<void> loadProfile(String uid) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getUserProfile(uid);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveUserProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> uploadImage(String filePath) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;
    
    state = const AsyncValue.loading();
    try {
      final downloadUrl = await _service.uploadProfileImage(currentProfile.uid, filePath);
      state = AsyncValue.data(currentProfile.copyWith(photoURL: downloadUrl));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> removeImage() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;
    
    state = const AsyncValue.loading();
    try {
      await _service.removeProfileImage(currentProfile.uid);
      state = AsyncValue.data(currentProfile.copyWith(photoURL: null));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileNotifier(service, ref);
});
