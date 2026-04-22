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
    required String sessionType,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final booking = BookingRequest(
        id: const Uuid().v4(),
        patientId: patientId,
        patientName: patientName,
        therapistId: therapistId,
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

final bookingProvider =
    StateNotifierProvider.autoDispose<BookingNotifier, BookingState>(
  (ref) => BookingNotifier(ref.read(bookingRepositoryProvider)),
);

final therapistDirectoryProvider =
    StreamProvider.autoDispose<List<TherapistModel>>(
  (ref) => TherapistRepository().watchAllTherapists(),
);
