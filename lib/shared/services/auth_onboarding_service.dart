import 'package:cloud_firestore/cloud_firestore.dart';

/// Service responsible for two-stage doctor onboarding:
/// Stage 1: Create /users/{uid} at signup
/// Stage 2: Create /doctors/{uid} as placeholder
/// Stage 3: Update /doctors/{uid} when profile completed
class AuthOnboardingService {
  final FirebaseFirestore _firestore;

  AuthOnboardingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// STAGE 1: Create /users/{uid} immediately after Firebase Auth signup for DOCTOR
  ///
  /// Called right after: FirebaseAuth.createUserWithEmailAndPassword()
  Future<void> createUserDocForNewDoctor({
    required String uid,
    required String email,
    required String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'role': 'DOCTOR',
        'profileCompleted': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastProfileUpdateAt': null,
        'metadata': {'signupSource': 'mobile', 'deviceId': 'device_info'},
      });
      print('✅ Created /users/$uid with role=DOCTOR, profileCompleted=false');
    } catch (e) {
      print('❌ Error creating user doc: $e');
      rethrow;
    }
  }

  /// Create /users/{uid} for a new PATIENT user
  ///
  /// Called right after: FirebaseAuth.createUserWithEmailAndPassword()
  Future<void> createUserDocForNewPatient({
    required String uid,
    required String email,
    required String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'role': 'PATIENT',
        'profileCompleted': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastProfileUpdateAt': null,
        'metadata': {'signupSource': 'mobile', 'deviceId': 'device_info'},
      });
      print('✅ Created /users/$uid with role=PATIENT, profileCompleted=false');
    } catch (e) {
      print('❌ Error creating patient user doc: $e');
      rethrow;
    }
  }

  /// STAGE 2: Create /doctors/{uid} placeholder immediately after /users creation
  ///
  /// This creates a minimal placeholder with profileCompleted=false
  /// Firestore rules will verify /users/{uid}.profileCompleted before allowing this
  Future<void> createDoctorPlaceholderDoc({required String uid}) async {
    try {
      await _firestore.collection('doctors').doc(uid).set({
        'ownerUid': uid,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'verification': {
          'status': 'PENDING',
          'verifiedAt': null,
          'rejectionReason': null,
        },
        'visibility': {'isListed': false, 'isSearchable': false},
        'metrics': {
          'ratingAvg': 0.0,
          'ratingCount': 0,
          'reviewCount': 0,
          'totalConsultations': 0,
        },
      });
      print('✅ Created /doctors/$uid placeholder');
    } catch (e) {
      print('❌ Error creating doctor placeholder: $e');
      rethrow;
    }
  }

  /// Check if doctor profile is complete
  Future<bool> isDoctorProfileComplete(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data()?['profileCompleted'] as bool? ?? false;
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      return false;
    }
  }

  /// Verify /doctors/{uid} exists; if missing, recreate it
  Future<bool> verifyDoctorDocExists(String uid) async {
    try {
      final docExists = await _firestore.collection('doctors').doc(uid).get();
      if (!docExists.exists) {
        print('⚠️  /doctors/$uid missing, recreating...');
        await createDoctorPlaceholderDoc(uid: uid);
        return true;
      }
      return true;
    } catch (e) {
      print('❌ Error verifying doctor doc: $e');
      return false;
    }
  }

  /// Update both /users and /doctors documents when profile is completed
  ///
  /// This atomically:
  /// 1. Updates /doctors/{uid} with profile data + profileCompleted=true
  /// 2. Updates /users/{uid}.profileCompleted=true
  Future<void> completeDocProfile({
    required String uid,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Use batch write for atomic operation
      final batch = _firestore.batch();

      // Update /doctors/{uid} with safe fields only + profileCompleted flag
      batch.update(_firestore.collection('doctors').doc(uid), {
        ...profileData,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update /users/{uid}.profileCompleted to true
      batch.update(_firestore.collection('users').doc(uid), {
        'profileCompleted': true,
        'lastProfileUpdateAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('✅ Doctor profile completed for UID: $uid');
    } catch (e) {
      print('❌ Error completing doctor profile: $e');
      rethrow;
    }
  }

  /// Get user role from /users/{uid}
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Fetch /users/{uid} document
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('❌ Error fetching user doc: $e');
      return null;
    }
  }

  /// Fetch /doctors/{uid} document
  Future<Map<String, dynamic>?> getDoctorDoc(String uid) async {
    try {
      final doc = await _firestore.collection('doctors').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('❌ Error fetching doctor doc: $e');
      return null;
    }
  }
}
