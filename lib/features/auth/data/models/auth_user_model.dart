import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({required super.uid, required super.email});

  factory AuthUserModel.fromFirebaseUser(dynamic user) {
    return AuthUserModel(uid: user.uid as String, email: user.email as String?);
  }
}
