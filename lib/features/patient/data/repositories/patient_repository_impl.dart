import '../../domain/entities/patient_profile.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_firestore_datasource.dart';
import '../models/patient_profile_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._datasource);

  final PatientFirestoreDatasource _datasource;

  @override
  Future<void> createProfile(PatientProfile profile) {
    final model = PatientProfileModel.fromEntity(profile);
    return _datasource.createProfile(model);
  }

  @override
  Future<PatientProfile?> getProfile(String uid) {
    return _datasource.getProfile(uid);
  }

  @override
  Future<void> updateProfile(PatientProfile profile) {
    final model = PatientProfileModel.fromEntity(profile);
    return _datasource.updateProfile(model);
  }
}
