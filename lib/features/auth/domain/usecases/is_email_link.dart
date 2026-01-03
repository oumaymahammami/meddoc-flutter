import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class IsEmailLink implements UseCase<bool, IsEmailLinkParams> {
  const IsEmailLink(this._repository);

  final AuthRepository _repository;

  @override
  Future<bool> call(IsEmailLinkParams params) async {
    return _repository.isSignInWithEmailLink(params.link);
  }
}

class IsEmailLinkParams {
  const IsEmailLinkParams(this.link);

  final String link;
}
