import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterUser extends UseCase<void, RegisterParams> {
  RegisterUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<void> call(RegisterParams params) {
    return _repo.register(
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}

class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.role,
  });
  final String email;
  final String password;
  final String role;
}
