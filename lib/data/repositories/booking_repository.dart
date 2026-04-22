// booking_repository.dart
// Handles Firestore operations for booking requests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_service.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseService _firebase;

  BookingRepository({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  Future<void> createBookingRequest(BookingRequest booking) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(booking.id)
        .set(booking.toMap());
  }

  Stream<List<BookingRequest>> streamPendingBookings(String therapistId) {
    return _firebase.firestore
        .collection('booking_requests')
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final bookings =
          snap.docs.map((d) => BookingRequest.fromMap(d.id, d.data())).toList();
      bookings.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return bookings;
    });
  }
}

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepository());
