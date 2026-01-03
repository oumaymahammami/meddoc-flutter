import '../entities/patient_profile.dart';

abstract class PatientRepository {
  Future<void> createProfile(PatientProfile profile);
  Future<PatientProfile?> getProfile(String uid);
  Future<void> updateProfile(PatientProfile profile);
}
