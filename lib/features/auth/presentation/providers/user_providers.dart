import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/user_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';

// Datasource provider
final userDatasourceProvider = Provider<UserDatasource>((ref) {
  return UserDatasourceImpl(firestore: FirebaseFirestore.instance);
});

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final datasource = ref.watch(userDatasourceProvider);
  return UserRepositoryImpl(datasource);
});

// Current user profile provider
final currentUserProfileProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, uid) async {
      final repository = ref.watch(userRepositoryProvider);
      return await repository.getUserProfile(uid);
    });

// Profile completion status provider
final isProfileCompletedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  // This will be set by the auth provider with the current user's UID
  // You'll need to integrate this with your auth state management
  return false;
});
