import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../patient/domain/entities/doctor.dart';
import '../../../patient/data/doctor_search_datasource.dart';
import '../../../patient/domain/entities/search_filters.dart';
import '../../domain/repositories/doctor_repository.dart';

/// Simple implementation of DoctorRepository using patient's datasource
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
    // Update profile logic using Firestore directly
    try {
      // Add uid to updates to ensure document can be created
      updates['uid'] = uid;

      // Use set with merge to create document if it doesn't exist
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
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
