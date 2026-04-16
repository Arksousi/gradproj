// firebase_service.dart
// Singleton wrapper for Firebase initialization and common Firestore helpers.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provides centralized access to Firebase Auth and Firestore instances.
/// Uses a singleton pattern to avoid multiple initializations.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  // --- Firebase instances ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // --- Collection references ---
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get patientsCollection => firestore.collection('patients');
  CollectionReference get therapistsCollection =>
      firestore.collection('therapists');

  // --- Auth helpers ---

  /// Returns the currently signed-in [User], or null if not authenticated.
  User? get currentUser => auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // --- Firestore helpers ---

  /// Fetches a single document from [collection] by [docId].
  Future<DocumentSnapshot<Object?>> getDocument(
      String collection, String docId) {
    return firestore.collection(collection).doc(docId).get();
  }

  /// Sets (creates or overwrites) a document at [collection]/[docId].
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) {
    return firestore
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  /// Updates specific fields of an existing document.
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) {
    return firestore.collection(collection).doc(docId).update(data);
  }

  /// Returns a stream of a collection's documents.
  Stream<QuerySnapshot> streamCollection(String collection) {
    return firestore.collection(collection).snapshots();
  }
}
