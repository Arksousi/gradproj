// register_usecase.dart
// Encapsulates the user registration business logic.

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Input parameters for the register use case.
class RegisterParams {
  final String name;
  final String email;
  final String password;

  /// Either "patient" or "therapist"
  final String role;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Use case that registers a new user via [AuthRepository].
/// Returns the new [UserModel] on success or throws an [Exception].
class RegisterUseCase {
  final AuthRepositoryBase _repository;

  RegisterUseCase(this._repository);

  Future<UserModel> call(RegisterParams params) async {
    return _repository.signUp(
      name: params.name,
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}
