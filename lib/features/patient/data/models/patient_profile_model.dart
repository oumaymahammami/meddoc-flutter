import '../../domain/entities/patient_profile.dart';

class PatientProfileModel extends PatientProfile {
  const PatientProfileModel({
    required super.uid,
    required super.email,
    required super.name,
    super.dateOfBirth,
    super.sex,
    super.address,
    super.allergies,
  });

  factory PatientProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return PatientProfileModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] as int)
          : null,
      sex: map['sex'] as String?,
      address: map['address'] as String?,
      allergies: map['allergies'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'sex': sex,
      'address': address,
      'allergies': allergies,
    };
  }

  factory PatientProfileModel.fromEntity(PatientProfile profile) {
    return PatientProfileModel(
      uid: profile.uid,
      email: profile.email,
      name: profile.name,
      dateOfBirth: profile.dateOfBirth,
      sex: profile.sex,
      address: profile.address,
      allergies: profile.allergies,
    );
  }
}
