import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_user_model.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AuthUserModel?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUserModel.fromFirebaseUser(user);
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendSignInLinkToEmail({required String email}) async {
    final settings = ActionCodeSettings(
      url: 'https://meddoc-bfe57.firebaseapp.com/finishSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.meddoc',
      androidMinimumVersion: '21',
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: settings,
    );
  }

  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<AuthUserModel?> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final credential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    final user = credential.user;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  Future<void> logout() => _auth.signOut();

  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }
}
