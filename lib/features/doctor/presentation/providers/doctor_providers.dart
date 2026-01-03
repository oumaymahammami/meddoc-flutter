import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../patient/domain/entities/doctor.dart';
import '../../../patient/data/doctor_search_datasource.dart';
import '../../data/repositories/doctor_repository_impl_simple.dart';
import '../../domain/repositories/doctor_repository.dart';

/// Provider for DoctorRepository
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepositoryImpl(dataSource: DoctorSearchDatasource());
});

/// Provider to get doctor profile by UID
final doctorProfileProvider = FutureProvider.autoDispose
    .family<Doctor?, String>((ref, uid) async {
      final repository = ref.watch(doctorRepositoryProvider);
      return await repository.getProfile(uid);
    });

/// Provider to search doctors
final doctorSearchProvider =
    FutureProvider.family<List<Doctor>, DoctorSearchParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(doctorRepositoryProvider);
      return await repository.searchDoctors(
        specialty: params.specialty,
        city: params.city,
        name: params.name,
      );
    });

/// Search parameters for doctors
class DoctorSearchParams {
  final String? specialty;
  final String? city;
  final String? name;

  DoctorSearchParams({this.specialty, this.city, this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorSearchParams &&
          runtimeType == other.runtimeType &&
          specialty == other.specialty &&
          city == other.city &&
          name == other.name;

  @override
  int get hashCode => specialty.hashCode ^ city.hashCode ^ name.hashCode;
}
