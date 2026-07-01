class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String state;
  final String city;
  final String address;
  final String language;
  final String occupation;
  final String? photoURL;
  final String authProvider;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.address = '',
    this.language = 'en',
    this.occupation = '',
    this.photoURL,
    this.authProvider = 'email',
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? country,
    String? state,
    String? city,
    String? address,
    String? language,
    String? occupation,
    String? photoURL,
    String? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      language: language ?? this.language,
      occupation: occupation ?? this.occupation,
      photoURL: photoURL ?? this.photoURL,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'country': country,
      'state': state,
      'city': city,
      'address': address,
      'language': language,
      'occupation': occupation,
      'photo_url': photoURL,
      'auth_provider': authProvider,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      uid: id,
      fullName: map['full_name'] ?? map['fullName'] ?? map['displayName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? map['phoneNumber'] ?? '',
      dateOfBirth: map['date_of_birth'] ?? map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      country: map['country'] ?? '',
      state: map['state'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      language: map['language'] ?? 'en',
      occupation: map['occupation'] ?? '',
      photoURL: map['photo_url'] ?? map['photoURL'] ?? map['photoUrl'],
      authProvider: map['auth_provider'] ?? map['authProvider'] ?? 'email',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null),
    );
  }
}
