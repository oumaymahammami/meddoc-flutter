import 'dart:developer';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDatasource _datasource;

  UserRepositoryImpl(this._datasource);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      log('Repository: Fetching user profile for UID: $uid');
      return await _datasource.getUserProfile(uid);
    } catch (e) {
      log('Repository error fetching user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> createUserProfile(String uid, UserProfile profile) async {
    try {
      log('Repository: Creating user profile for UID: $uid');
      await _datasource.createUserProfile(uid, profile);
      log('Repository: User profile created');
    } catch (e) {
      log('Repository error creating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> markProfileAsComplete(String uid) async {
    try {
      log('Repository: Marking profile as complete for UID: $uid');
      await _datasource.updateProfileCompletionStatus(uid, true);
      log('Repository: Profile marked as complete');
    } catch (e) {
      log('Repository error marking profile complete: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String uid) async {
    try {
      log('Repository: Deleting user profile for UID: $uid');
      await _datasource.deleteUserProfile(uid);
      log('Repository: User profile deleted');
    } catch (e) {
      log('Repository error deleting user profile: $e');
      rethrow;
    }
  }
}
