// booking_provider.dart
// Riverpod providers for booking requests and therapist directory.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/therapist_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/therapist_repository.dart';

class BookingState {
  final bool isLoading;
  final bool success;
  final String? errorMessage;

  const BookingState({
    this.isLoading = false,
    this.success = false,
    this.errorMessage,
  });

  BookingState copyWith({
    bool? isLoading,
    bool? success,
    String? errorMessage,
  }) =>
      BookingState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRepository _repo;

  BookingNotifier(this._repo) : super(const BookingState());

  Future<void> createBooking({
    required String patientId,
    required String patientName,
    required String therapistId,
    required String therapistName,
    required String sessionType,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final booking = BookingRequest(
        id: const Uuid().v4(),
        patientId: patientId,
        patientName: patientName,
        therapistId: therapistId,
        therapistName: therapistName,
        status: 'pending',
        requestedAt: DateTime.now(),
        sessionType: sessionType,
        consentGiven: true,
      );
      await _repo.createBookingRequest(booking);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// ── Therapist-side: stream pending booking requests ──────────────────────────
final pendingBookingsProvider =
    StreamProvider.autoDispose.family<List<BookingRequest>, String>(
  (ref, therapistId) =>
      ref.read(bookingRepositoryProvider).streamPendingBookings(therapistId),
);

// ── Patient-side: stream own booking requests ────────────────────────────────
final patientBookingsProvider =
    StreamProvider.autoDispose.family<List<BookingRequest>, String>(
  (ref, patientId) =>
      ref.read(bookingRepositoryProvider).streamPatientBookings(patientId),
);

// ── Therapist-side: accept / decline actions ─────────────────────────────────
class BookingActionNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingRepository _repo;
  BookingActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> accept(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.acceptBooking(bookingId));
  }

  Future<void> decline(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.declineBooking(bookingId));
  }
}

final bookingActionProvider =
    StateNotifierProvider.autoDispose<BookingActionNotifier, AsyncValue<void>>(
  (ref) => BookingActionNotifier(ref.read(bookingRepositoryProvider)),
);

final bookingProvider =
    StateNotifierProvider.autoDispose<BookingNotifier, BookingState>(
  (ref) => BookingNotifier(ref.read(bookingRepositoryProvider)),
);

final therapistDirectoryProvider =
    StreamProvider.autoDispose<List<TherapistModel>>(
  (ref) => TherapistRepository().watchAllTherapists(),
);
