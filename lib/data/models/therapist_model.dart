// therapist_model.dart
// Data model for a therapist's profile stored in Firestore.

/// Represents therapist profile data stored at: therapists/{uid}
class TherapistModel {
  final String uid;
  final String name;
  final String email;

  /// List of patient UIDs assigned to this therapist.
  final List<String> patients;

  final String specialization;
  final String bio;

  const TherapistModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.patients,
    required this.specialization,
    required this.bio,
  });

  // --- Serialization ---

  factory TherapistModel.fromMap(String uid, Map<String, dynamic> map) {
    return TherapistModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      patients: List<String>.from(
          (map['patients'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      specialization: map['specialization'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'patients': patients,
      'specialization': specialization,
      'bio': bio,
    };
  }

  TherapistModel copyWith({
    String? name,
    String? email,
    List<String>? patients,
    String? specialization,
    String? bio,
  }) {
    return TherapistModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      patients: patients ?? this.patients,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
    );
  }

  @override
  String toString() =>
      'TherapistModel(uid: $uid, name: $name, patients: ${patients.length})';
}
