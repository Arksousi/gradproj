// patient_model.dart
// Data model for a patient's assessment submission stored in Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents patient assessment data stored at: patients/{uid}
class PatientModel {
  final String uid;

  /// Patient's display name (from users collection)
  final String name;

  /// Email (from users collection)
  final String email;

  /// List of 30 answer indices (0–3) corresponding to assessment questions.
  final List<int> assessment;

  /// Free-text description of the patient's feelings.
  final String description;

  /// UID of the assigned therapist (empty if not yet assigned).
  final String therapistId;

  /// Timestamp of when the assessment was submitted.
  final DateTime? submittedAt;

  const PatientModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.assessment,
    required this.description,
    required this.therapistId,
    this.submittedAt,
  });

  // --- Serialization ---

  factory PatientModel.fromMap(String uid, Map<String, dynamic> map) {
    return PatientModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      assessment: List<int>.from(
          (map['assessment'] as List<dynamic>?)?.map((e) => e as int) ?? []),
      description: map['description'] as String? ?? '',
      therapistId: map['therapistId'] as String? ?? '',
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'assessment': assessment,
      'description': description,
      'therapistId': therapistId,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  PatientModel copyWith({
    String? name,
    String? email,
    List<int>? assessment,
    String? description,
    String? therapistId,
    DateTime? submittedAt,
  }) {
    return PatientModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      assessment: assessment ?? this.assessment,
      description: description ?? this.description,
      therapistId: therapistId ?? this.therapistId,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  /// Computes total score (sum of all answer indices).
  int get totalScore => assessment.fold(0, (acc, v) => acc + v);

  @override
  String toString() =>
      'PatientModel(uid: $uid, name: $name, totalScore: $totalScore)';
}
