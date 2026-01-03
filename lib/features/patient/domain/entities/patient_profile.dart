class PatientProfile {
  const PatientProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.dateOfBirth,
    this.sex,
    this.address,
    this.allergies,
  });

  final String uid;
  final String email;
  final String name;
  final DateTime? dateOfBirth;
  final String? sex; // 'M', 'F', or other
  final String? address;
  final String? allergies; // Comma-separated or freeform text

  PatientProfile copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? dateOfBirth,
    String? sex,
    String? address,
    String? allergies,
  }) {
    return PatientProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      address: address ?? this.address,
      allergies: allergies ?? this.allergies,
    );
  }
}
