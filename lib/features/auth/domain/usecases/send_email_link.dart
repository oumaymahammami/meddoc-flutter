import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendEmailLink implements UseCase<void, SendEmailLinkParams> {
  const SendEmailLink(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(SendEmailLinkParams params) {
    return _repository.sendSignInLinkToEmail(email: params.email);
  }
}

class SendEmailLinkParams {
  const SendEmailLinkParams({required this.email});

  final String email;
}
