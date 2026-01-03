import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import '../../domain/entities/user_profile.dart';

abstract class UserDatasource {
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> createUserProfile(String uid, UserProfile profile);
  Future<void> updateProfileCompletionStatus(String uid, bool completed);
  Future<void> deleteUserProfile(String uid);
}

class UserDatasourceImpl implements UserDatasource {
  final FirebaseFirestore _firestore;
  static const String collectionPath = 'users';

  UserDatasourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      log('Fetching user profile for UID: $uid');
      final doc = await _firestore.collection(collectionPath).doc(uid).get();
      if (doc.exists) {
        log('User profile found for UID: $uid');
        return UserProfile.fromMap(doc.data()!, uid);
      }
      log('No user profile found for UID: $uid');
      return null;
    } catch (e) {
      log('Error fetching user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> createUserProfile(String uid, UserProfile profile) async {
    try {
      log('Creating user profile for UID: $uid');
      final data = {
        'uid': uid,
        'email': profile.email,
        'phone': profile.phone,
        'role': profile.role.name,
        'profileCompleted': false, // Always false on creation
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(collectionPath).doc(uid).set(data);
      log('User profile created successfully for UID: $uid');
    } catch (e) {
      log('Error creating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfileCompletionStatus(String uid, bool completed) async {
    try {
      log('Updating profile completion status for UID: $uid to $completed');
      await _firestore.collection(collectionPath).doc(uid).update({
        'profileCompleted': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('Profile completion status updated');
    } catch (e) {
      log('Error updating profile completion status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String uid) async {
    try {
      log('Deleting user profile for UID: $uid');
      await _firestore.collection(collectionPath).doc(uid).delete();
      log('User profile deleted successfully');
    } catch (e) {
      log('Error deleting user profile: $e');
      rethrow;
    }
  }
}
