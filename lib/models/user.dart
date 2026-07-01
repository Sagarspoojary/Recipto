class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String membership; // "Free" or "Pro"
  final double storageUsed; // In MB
  final double storageLimit; // In MB

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.membership = 'Free',
    this.storageUsed = 12.4,
    this.storageLimit = 100.0,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? membership,
    double? storageUsed,
    double? storageLimit,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      membership: membership ?? this.membership,
      storageUsed: storageUsed ?? this.storageUsed,
      storageLimit: storageLimit ?? this.storageLimit,
    );
  }
}
