import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _datasource.authStateChanges();
  }

  @override
  Future<void> login({required String email, required String password}) {
    return _datasource.login(email: email, password: password);
  }

  @override
  Future<void> logout() {
    return _datasource.logout();
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) {
    return _datasource.register(email: email, password: password, role: role);
  }

  @override
  Future<String?> getCurrentUserRole() {
    return _datasource.getCurrentUserRole();
  }

  @override
  Future<void> sendSignInLinkToEmail({required String email}) {
    return _datasource.sendSignInLinkToEmail(email: email);
  }

  @override
  bool isSignInWithEmailLink(String link) {
    return _datasource.isSignInWithEmailLink(link);
  }

  @override
  Future<AuthUser?> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final user = await _datasource.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    if (user == null) return null;
    return AuthUserModel(uid: user.uid, email: user.email);
  }
}
