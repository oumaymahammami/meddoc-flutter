import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUser extends UseCase<void, NoParams> {
  LogoutUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<void> call(NoParams params) {
    return _repo.logout();
  }
}
