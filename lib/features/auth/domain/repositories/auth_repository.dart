import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<void> register({
    required String email,
    required String password,
    required String role,
  });
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<String?> getCurrentUserRole();
  Future<void> sendSignInLinkToEmail({required String email});
  bool isSignInWithEmailLink(String link);
  Future<AuthUser?> signInWithEmailLink({
    required String email,
    required String emailLink,
  });
}
