import '../../domain/repositories/doctor_repository.dart';
import '../../../patient/domain/entities/doctor.dart';
import '../../../patient/data/doctor_search_datasource.dart';
import '../../../patient/domain/entities/search_filters.dart';

/// Simple implementation of DoctorRepository
class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorSearchDatasource _dataSource;

  DoctorRepositoryImpl({DoctorSearchDatasource? dataSource})
    : _dataSource = dataSource ?? DoctorSearchDatasource();

  @override
  Future<Doctor?> getProfile(String uid) async {
    try {
      final doctors = await _dataSource.searchDoctors(const SearchFilters());
      return doctors.firstWhere(
        (doc) => doc.id == uid,
        orElse: () => throw Exception('Doctor not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    // Implement profile update logic
    // For now, this is a placeholder
  }

  @override
  Future<List<Doctor>> searchDoctors({
    String? specialty,
    String? city,
    String? name,
  }) async {
    final doctors = await _dataSource.searchDoctors(
      SearchFilters(specialtyId: specialty, city: city),
    );

    if (name != null && name.isNotEmpty) {
      final lowerName = name.toLowerCase();
      return doctors
          .where((doctor) => doctor.fullName.toLowerCase().contains(lowerName))
          .toList();
    }

    return doctors;
  }
}
