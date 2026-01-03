import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile_model.dart';

abstract class DoctorFirestoreDatasource {
  Future<DoctorProfileModel?> getProfile(String uid);
  Future<void> createProfile(String uid, DoctorProfileModel profile);
  Future<void> updateProfile(String uid, Map<String, dynamic> updates);
  Future<void> deleteProfile(String uid);
  Future<List<DoctorProfileModel>> searchDoctors({
    required String? specialtyId,
    required String? city,
    required bool? acceptingPatients,
    int limit = 20,
  });
}

class DoctorFirestoreDatasourceImpl implements DoctorFirestoreDatasource {
  final FirebaseFirestore _firestore;
  static const String collectionPath = 'doctors';

  DoctorFirestoreDatasourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DoctorProfileModel?> getProfile(String uid) async {
    try {
      log('Fetching doctor profile for UID: $uid');
      final doc = await _firestore.collection(collectionPath).doc(uid).get();
      if (doc.exists) {
        log('Profile found for UID: $uid');
        return DoctorProfileModel.fromMap(doc.data()!, uid);
      }
      log('No profile found for UID: $uid');
      return null;
    } catch (e) {
      log('Error fetching profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> createProfile(String uid, DoctorProfileModel profile) async {
    try {
      log('Creating profile for UID: $uid');
      final data = profile.toMap(includeAdminOnly: false);
      data['uid'] = uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(collectionPath)
          .doc(uid)
          .set(data, SetOptions(merge: false));
      log('Profile created successfully for UID: $uid');
    } catch (e) {
      log('Error creating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      log('Updating profile for UID: $uid');
      // Filter to ensure only safe fields are updated
      final safeUpdates = _filterSafeFields(updates);
      safeUpdates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(collectionPath).doc(uid).update(safeUpdates);
      log('Profile updated successfully for UID: $uid');
    } catch (e) {
      log('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      log('Deleting profile for UID: $uid');
      await _firestore.collection(collectionPath).doc(uid).delete();
      log('Profile deleted successfully for UID: $uid');
    } catch (e) {
      log('Error deleting profile: $e');
      rethrow;
    }
  }

  @override
  Future<List<DoctorProfileModel>> searchDoctors({
    required String? specialtyId,
    required String? city,
    required bool? acceptingPatients,
    int limit = 20,
  }) async {
    try {
      log(
        'Searching doctors: specialtyId=$specialtyId, city=$city, accepting=$acceptingPatients, limit=$limit',
      );
      Query query = _firestore.collection(collectionPath);

      if (specialtyId != null) {
        query = query.where('specialtyId', isEqualTo: specialtyId);
      }

      if (city != null) {
        query = query.where('clinic.city', isEqualTo: city);
      }

      if (acceptingPatients != null) {
        query = query.where(
          'acceptingNewPatients',
          isEqualTo: acceptingPatients,
        );
      }

      query = query.where('visibility.isPublic', isEqualTo: true);

      // Use smaller limit to reduce memory usage on web
      final snapshot = await query.limit(limit).get();
      final results = [
        for (final doc in snapshot.docs)
          DoctorProfileModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
      ];
      log('Found ${results.length} doctors');
      return results;
    } catch (e) {
      log('Error searching doctors: $e');
      rethrow;
    }
  }

  /// Filter to only allow editable fields (doctor-safe fields)
  Map<String, dynamic> _filterSafeFields(Map<String, dynamic> data) {
    const safeFields = {
      'fullName',
      'bio',
      'specialtyId',
      'specialtyName',
      'requestedSpecialtyId',
      'contacts.phone',
      'contacts.email',
      'clinic.cabinetNumber',
      'clinic.addressLine',
      'clinic.city',
      'clinic.postalCode',
      'clinic.geo',
      'consultationModes.inPerson',
      'consultationModes.video',
      'pricing.inPersonTND',
      'pricing.videoTND',
      'pricing.currency',
      'languages',
      'acceptingNewPatients',
      'photo.storagePath',
    };

    final filtered = <String, dynamic>{};

    data.forEach((key, value) {
      if (safeFields.contains(key)) {
        filtered[key] = value;
      } else if (key == 'contacts' && value is Map) {
        final contactsMap = <String, dynamic>{};
        // ignore: unnecessary_cast
        (value as Map).forEach((k, v) {
          if (safeFields.contains('contacts.$k')) {
            contactsMap[k] = v;
          }
        });
        if (contactsMap.isNotEmpty) {
          filtered['contacts'] = contactsMap;
        }
      } else if (key == 'clinic' && value is Map) {
        final clinicMap = <String, dynamic>{};
        // ignore: unnecessary_cast
        (value as Map).forEach((k, v) {
          if (safeFields.contains('clinic.$k')) {
            clinicMap[k] = v;
          }
        });
        if (clinicMap.isNotEmpty) {
          filtered['clinic'] = clinicMap;
        }
      } else if (key == 'consultationModes' && value is Map) {
        final modesMap = <String, dynamic>{};
        // ignore: unnecessary_cast
        (value as Map).forEach((k, v) {
          if (safeFields.contains('consultationModes.$k')) {
            modesMap[k] = v;
          }
        });
        if (modesMap.isNotEmpty) {
          filtered['consultationModes'] = modesMap;
        }
      } else if (key == 'pricing' && value is Map) {
        final pricingMap = <String, dynamic>{};
        // ignore: unnecessary_cast
        (value as Map).forEach((k, v) {
          if (safeFields.contains('pricing.$k')) {
            pricingMap[k] = v;
          }
        });
        if (pricingMap.isNotEmpty) {
          filtered['pricing'] = pricingMap;
        }
      } else if (key == 'photo' && value is Map) {
        final photoMap = <String, dynamic>{};
        // ignore: unnecessary_cast
        (value as Map).forEach((k, v) {
          if (safeFields.contains('photo.$k')) {
            photoMap[k] = v;
          }
        });
        if (photoMap.isNotEmpty) {
          filtered['photo'] = photoMap;
        }
      }
    });

    return filtered;
  }
}
