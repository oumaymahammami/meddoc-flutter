import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_profile_model.dart';

class PatientFirestoreDatasource {
  PatientFirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createProfile(PatientProfileModel profile) async {
    await _firestore
        .collection('patients')
        .doc(profile.uid)
        .set(profile.toMap());
  }

  Future<PatientProfileModel?> getProfile(String uid) async {
    final doc = await _firestore.collection('patients').doc(uid).get();
    if (!doc.exists) return null;
    return PatientProfileModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateProfile(PatientProfileModel profile) async {
    await _firestore
        .collection('patients')
        .doc(profile.uid)
        .update(profile.toMap());
  }
}
