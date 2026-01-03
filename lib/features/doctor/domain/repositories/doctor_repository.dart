import '../../../patient/domain/entities/doctor.dart';

/// Repository interface for doctor-related operations
abstract class DoctorRepository {
  /// Get a doctor profile by UID
  Future<Doctor?> getProfile(String uid);

  /// Update doctor profile
  Future<void> updateProfile(String uid, Map<String, dynamic> updates);

  /// Search for doctors based on criteria
  Future<List<Doctor>> searchDoctors({
    String? specialty,
    String? city,
    String? name,
  });
}
