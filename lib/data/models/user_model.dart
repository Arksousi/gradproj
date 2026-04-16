// user_model.dart
// Data model representing a registered PsyCare user (patient or therapist).

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents user authentication & profile data stored in Firestore
/// at the path: users/{uid}
class UserModel {
  final String uid;
  final String name;
  final String email;

  /// Either "patient" or "therapist"
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  // --- Serialization ---

  /// Creates a [UserModel] from a Firestore document map.
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy with updated fields.
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, email: $email, role: $role)';
}
