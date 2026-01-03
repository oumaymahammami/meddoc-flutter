import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LoginUser extends UseCase<void, LoginParams> {
  LoginUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<void> call(LoginParams params) {
    return _repo.login(email: params.email, password: params.password);
  }
}

class LoginParams {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}
