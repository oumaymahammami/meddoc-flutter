import 'package:equatable/equatable.dart';

enum UserRole { doctor, patient, admin }

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    this.phone,
    required this.role,
    required this.profileCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String? phone;
  final UserRole role;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile copyWith({
    String? uid,
    String? email,
    String? phone,
    UserRole? role,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileCompleted': profileCompleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: UserRole.values.byName(map['role'] as String),
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    phone,
    role,
    profileCompleted,
    createdAt,
    updatedAt,
  ];
}
