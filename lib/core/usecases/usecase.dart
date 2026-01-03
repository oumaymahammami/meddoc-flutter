abstract class UseCase<T, Params> {
  const UseCase();
  Future<T> call(Params params);
}

class NoParams {
  const NoParams();
}
