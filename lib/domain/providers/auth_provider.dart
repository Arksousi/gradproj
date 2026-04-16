// auth_provider.dart
// Riverpod providers for authentication state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../usecases/login_usecase.dart';
import '../usecases/register_usecase.dart';

// --- Repository provider ---

/// Provides the singleton [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// --- Auth state ---

/// Represents the authentication state of the app.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// --- Auth notifier ---

/// StateNotifier that manages [AuthState] and exposes login/register/logout.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  AuthNotifier(this._repository)
      : _loginUseCase = LoginUseCase(_repository),
        _registerUseCase = RegisterUseCase(_repository),
        super(const AuthState()) {
    _checkCurrentUser();
  }

  /// Checks if a user is already signed in on app start.
  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false, clearError: true);
    } catch (_) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  /// Attempts to sign in with [email] and [password].
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _loginUseCase(
          LoginParams(email: email, password: password));
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Registers a new user and signs them in.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _registerUseCase(RegisterParams(
        name: name,
        email: email,
        password: password,
        role: role,
      ));
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Signs out the current user and clears state.
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

/// Main provider for [AuthNotifier] — consumed by all auth-aware screens.
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Convenience provider for the current [UserModel] (nullable).
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
