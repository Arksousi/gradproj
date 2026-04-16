// auth_repository.dart
// Handles all Firebase Authentication operations and user profile management.

import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

/// Abstract base class defining the auth contract (supports polymorphism).
abstract class AuthRepositoryBase {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<User?> get authStateChanges;
}

/// Concrete implementation using Firebase Auth + Firestore.
class AuthRepository implements AuthRepositoryBase {
  final FirebaseService _firebase;

  AuthRepository({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  @override
  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  /// Signs in an existing user with email and password.
  /// Returns the full [UserModel] from Firestore on success.
  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      return _fetchUserModel(uid);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Registers a new user and creates Firestore documents for their role.
  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      // Write to users collection
      await _firebase.setDocument('users', uid, user.toMap());

      // Create role-specific document
      if (role == 'patient') {
        await _firebase.setDocument('patients', uid, {
          'name': user.name,
          'email': user.email,
          'assessment': [],
          'description': '',
          'therapistId': '',
          'submittedAt': null,
        });
      } else if (role == 'therapist') {
        await _firebase.setDocument('therapists', uid, {
          'name': user.name,
          'email': user.email,
          'patients': [],
          'specialization': '',
          'bio': '',
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Signs the current user out.
  @override
  Future<void> signOut() async {
    await _firebase.auth.signOut();
  }

  /// Returns the [UserModel] of the currently authenticated user, or null.
  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebase.currentUser;
    if (firebaseUser == null) return null;
    try {
      return await _fetchUserModel(firebaseUser.uid);
    } catch (_) {
      return null;
    }
  }

  // --- Private helpers ---

  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _firebase.getDocument('users', uid);
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromMap(uid, doc.data() as Map<String, dynamic>);
  }

  /// Maps [FirebaseAuthException] to user-friendly messages.
  Exception _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'weak-password':
        return Exception('Password is too weak. Use at least 6 characters.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}
