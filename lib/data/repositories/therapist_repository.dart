// therapist_repository.dart
// Handles Firestore CRUD operations for the therapists collection.

import '../../core/services/firebase_service.dart';
import '../models/therapist_model.dart';

/// Abstract base defining the therapist data contract.
abstract class TherapistRepositoryBase {
  Future<TherapistModel?> getTherapist(String uid);
  Future<void> updateProfile(TherapistModel therapist);
  Stream<TherapistModel?> watchTherapist(String uid);
  Future<List<TherapistModel>> getAllTherapists();
}

/// Concrete Firestore implementation of [TherapistRepositoryBase].
class TherapistRepository implements TherapistRepositoryBase {
  final FirebaseService _firebase;

  TherapistRepository({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  /// Fetches a therapist document by UID.
  @override
  Future<TherapistModel?> getTherapist(String uid) async {
    try {
      final doc = await _firebase.getDocument('therapists', uid);
      if (!doc.exists) return null;
      return TherapistModel.fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch therapist: $e');
    }
  }

  /// Updates a therapist's profile fields.
  @override
  Future<void> updateProfile(TherapistModel therapist) async {
    try {
      await _firebase.setDocument(
          'therapists', therapist.uid, therapist.toMap());
    } catch (e) {
      throw Exception('Failed to update therapist profile: $e');
    }
  }

  /// Returns a real-time stream of a therapist's document.
  @override
  Stream<TherapistModel?> watchTherapist(String uid) {
    return _firebase.firestore
        .collection('therapists')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TherapistModel.fromMap(uid, doc.data()!);
    });
  }

  /// Returns all therapists (used when patient selects a therapist).
  @override
  Future<List<TherapistModel>> getAllTherapists() async {
    try {
      final snapshot =
          await _firebase.firestore.collection('therapists').get();
      return snapshot.docs
          .map((doc) => TherapistModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch therapists: $e');
    }
  }

  /// Returns a real-time stream of all therapists.
  Stream<List<TherapistModel>> watchAllTherapists() {
    return _firebase.firestore.collection('therapists').snapshots().map(
        (snap) =>
            snap.docs.map((doc) => TherapistModel.fromMap(doc.id, doc.data())).toList());
  }

  /// Updates therapist availability flags.
  Future<void> updateAvailability(String uid,
      {bool? isOnShift, bool? isAvailableForImmediate}) async {
    final data = <String, dynamic>{};
    if (isOnShift != null) { data['isOnShift'] = isOnShift; }
    if (isAvailableForImmediate != null) {
      data['isAvailableForImmediate'] = isAvailableForImmediate;
    }
    if (data.isNotEmpty) {
      await _firebase.firestore.collection('therapists').doc(uid).update(data);
    }
  }
}
