class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;
  final DateTime createdAt;


  final List<String> skills;
  final String experience;
  final String hourlyRate;
  final String bio;
  final double rating;
  final int reviewCount;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = '',
    required this.createdAt,
    this.skills = const [],
    this.experience = '',
    this.hourlyRate = '',
    this.bio = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
  });


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'skills': skills,
      'experienceYears': experience,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
    };
  }


  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      skills: List<String>.from(map['skills'] ?? []),
      experience: (map['experienceYears'] ?? '').toString(),
      hourlyRate: (map['hourlyRate'] ?? '').toString(),
      bio: map['bio'] ?? '',
      rating: double.tryParse((map['rating'] ?? 0.0).toString()) ?? 0.0,
      reviewCount: int.tryParse((map['reviewCount'] ?? 0).toString()) ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }
}