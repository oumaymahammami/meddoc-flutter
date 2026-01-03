import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> createUserProfile(String uid, UserProfile profile);
  Future<void> markProfileAsComplete(String uid);
  Future<void> deleteUserProfile(String uid);
}
