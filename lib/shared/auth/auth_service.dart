import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> register({
    required String email,
    required String password,
    required String role, // "doctor" ou "patient"
    String? name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      print('✅ User created: $uid');

      // ✅ STEP 1: Create /users/{uid} with role
      await _db.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'uid': uid,
        if (name != null) 'name': name,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Created /users/$uid');

      // ✅ STEP 2: If doctor, create /doctors/{uid} placeholder
      if (role == 'doctor') {
        print('📋 Creating doctor placeholder for $uid...');
        // Note: Doctor placeholder creation is handled by AuthOnboardingService
        // in the signup flow
      }
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch the user role from Firestore
      final userDoc = await _db
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final userRole = userDoc.data()?['role'] as String;

      return userRole;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      rethrow;
    }
  }

  String? getCurrentUid() => _auth.currentUser?.uid;

  Future<void> logout() async => _auth.signOut();
}
