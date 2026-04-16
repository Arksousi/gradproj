// login_usecase.dart
// Encapsulates the sign-in business logic, decoupling it from the UI layer.

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Input parameters for the login use case.
class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

/// Use case that executes user sign-in via [AuthRepository].
/// Returns [UserModel] on success or throws an [Exception] on failure.
class LoginUseCase {
  final AuthRepositoryBase _repository;

  LoginUseCase(this._repository);

  Future<UserModel> call(LoginParams params) async {
    return _repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}
