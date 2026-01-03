import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class GetCurrentRole extends UseCase<String?, NoParams> {
  GetCurrentRole(this._repo);
  final AuthRepository _repo;

  @override
  Future<String?> call(NoParams params) {
    return _repo.getCurrentUserRole();
  }
}
