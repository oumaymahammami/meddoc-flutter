import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailLink
    implements UseCase<AuthUser?, SignInWithEmailLinkParams> {
  const SignInWithEmailLink(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser?> call(SignInWithEmailLinkParams params) {
    return _repository.signInWithEmailLink(
      email: params.email,
      emailLink: params.emailLink,
    );
  }
}

class SignInWithEmailLinkParams {
  const SignInWithEmailLinkParams({
    required this.email,
    required this.emailLink,
  });

  final String email;
  final String emailLink;
}
