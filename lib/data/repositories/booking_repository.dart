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

  Future<void> acceptBooking(String bookingId) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(bookingId)
        .update({'status': 'confirmed'});
  }

  Future<void> declineBooking(String bookingId) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(bookingId)
        .update({'status': 'declined'});
  }

  Future<void> cancelBooking(String bookingId,
      {required String cancelledBy, String? reason}) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(bookingId)
        .update({
      'status': 'cancelled_by_$cancelledBy',
      if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
    });
  }

  Future<void> requestReschedule(String bookingId, String note) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(bookingId)
        .update({
      'status': 'reschedule_requested',
      'rescheduleNote': note,
    });
  }

  Future<void> confirmReschedule(String bookingId) async {
    await _firebase.firestore
        .collection('booking_requests')
        .doc(bookingId)
        .update({'status': 'confirmed'});
  }

  Stream<List<BookingRequest>> streamConfirmedBookings(String therapistId) {
    return _firebase.firestore
        .collection('booking_requests')
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snap) {
      final bookings =
          snap.docs.map((d) => BookingRequest.fromMap(d.id, d.data())).toList();
      bookings.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return bookings;
    });
  }

  Stream<List<BookingRequest>> streamPatientBookings(String patientId) {
    return _firebase.firestore
        .collection('booking_requests')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final bookings =
          snap.docs.map((d) => BookingRequest.fromMap(d.id, d.data())).toList();
      bookings.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return bookings;
    });
  }
}

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepository());
