// patient_repository.dart
// Handles Firestore CRUD operations for the patients collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../models/patient_model.dart';

/// Abstract base defining the patient data contract.
abstract class PatientRepositoryBase {
  Future<PatientModel?> getPatient(String uid);
  Future<void> saveAssessment(String uid, List<int> answers);
  Future<void> saveDescription(String uid, String description);
  Future<void> submitAssessment({
    required String uid,
    required List<int> answers,
    required String description,
    required String therapistId,
  });
  Stream<PatientModel?> watchPatient(String uid);
}

/// Concrete Firestore implementation of [PatientRepositoryBase].
class PatientRepository implements PatientRepositoryBase {
  final FirebaseService _firebase;

  PatientRepository({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  /// Fetches a single patient document by UID.
  @override
  Future<PatientModel?> getPatient(String uid) async {
    try {
      final doc = await _firebase.getDocument('patients', uid);
      if (!doc.exists) return null;
      return PatientModel.fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch patient: $e');
    }
  }

  /// Saves assessment answers without submitting.
  @override
  Future<void> saveAssessment(String uid, List<int> answers) async {
    try {
      await _firebase.updateDocument('patients', uid, {
        'assessment': answers,
      });
    } catch (e) {
      throw Exception('Failed to save assessment: $e');
    }
  }

  /// Saves the patient's free-text description.
  @override
  Future<void> saveDescription(String uid, String description) async {
    try {
      await _firebase.updateDocument('patients', uid, {
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to save description: $e');
    }
  }

  /// Submits the complete assessment to Firestore and notifies the therapist.
  @override
  Future<void> submitAssessment({
    required String uid,
    required List<int> answers,
    required String description,
    required String therapistId,
  }) async {
    try {
      // Update patient document
      await _firebase.setDocument('patients', uid, {
        'assessment': answers,
        'description': description,
        'therapistId': therapistId,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Add patient UID to therapist's patients list (if therapist assigned)
      if (therapistId.isNotEmpty) {
        await _firebase.firestore
            .collection('therapists')
            .doc(therapistId)
            .update({
          'patients': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      throw Exception('Failed to submit assessment: $e');
    }
  }

  /// Returns a real-time stream of a patient's document.
  @override
  Stream<PatientModel?> watchPatient(String uid) {
    return _firebase.firestore
        .collection('patients')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return PatientModel.fromMap(uid, doc.data()!);
    });
  }

  /// Fetches all patients for a given therapist UID.
  Future<List<PatientModel>> getPatientsForTherapist(
      String therapistId) async {
    try {
      final snapshot = await _firebase.firestore
          .collection('patients')
          .where('therapistId', isEqualTo: therapistId)
          .get();
      return snapshot.docs
          .map((doc) =>
              PatientModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch patients: $e');
    }
  }

  /// Saves the emotional support session data as a nested map on the patient doc.
  Future<void> saveEmotionalSupport({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firebase.setDocument('patients', uid, {
        'emotionalSupport': {
          ...data,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      throw Exception('Failed to save emotional support data: $e');
    }
  }

  /// Returns a real-time stream of all patients for a given therapist.
  Stream<List<PatientModel>> watchPatientsForTherapist(String therapistId) {
    return _firebase.firestore
        .collection('patients')
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PatientModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}
