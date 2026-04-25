// patient_provider.dart
// Riverpod providers for patient data and assessment state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/therapist_repository.dart';
import 'auth_provider.dart';

// --- Repository provider ---

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

final therapistRepositoryProvider = Provider<TherapistRepository>((ref) {
  return TherapistRepository();
});

// --- Patient stream provider ---

/// Watches the current patient's Firestore document in real time.
final currentPatientProvider =
    StreamProvider.autoDispose<PatientModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final repo = ref.watch(patientRepositoryProvider);
  return repo.watchPatient(user.uid);
});

// --- Assessment state ---

/// Holds the in-progress assessment answers (list of 30 answer indices).
class AssessmentState {
  /// Map from question index → selected answer index (0–3)
  final Map<int, int> answers;
  final int currentPage;
  final bool isSubmitting;
  final String? errorMessage;

  const AssessmentState({
    this.answers = const {},
    this.currentPage = 0,
    this.isSubmitting = false,
    this.errorMessage,
  });

  AssessmentState copyWith({
    Map<int, int>? answers,
    int? currentPage,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssessmentState(
      answers: answers ?? this.answers,
      currentPage: currentPage ?? this.currentPage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// Returns the answers as an ordered list of 30 ints (defaults to 0).
  List<int> toAnswerList(int total) {
    return List.generate(total, (i) => answers[i] ?? 0);
  }

  int get answeredCount => answers.length;
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final PatientRepository _repository;
  final TherapistRepository _therapistRepository;
  final String _patientUid;

  AssessmentNotifier(this._repository, this._therapistRepository, this._patientUid)
      : super(const AssessmentState());

  void setAnswer(int questionIndex, int answerIndex) {
    final updated = Map<int, int>.from(state.answers);
    updated[questionIndex] = answerIndex;
    state = state.copyWith(answers: updated);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<bool> submitAssessment({String description = ''}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      // Find first available therapist (simplified assignment)
      final therapists = await _therapistRepository.getAllTherapists();
      final therapistId = therapists.isNotEmpty ? therapists.first.uid : '';

      await _repository.submitAssessment(
        uid: _patientUid,
        answers: state.toAnswerList(30),
        description: description,
        therapistId: therapistId,
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Provider for [AssessmentNotifier] — scoped to the current patient UID.
final assessmentProvider =
    StateNotifierProvider.autoDispose<AssessmentNotifier, AssessmentState>(
        (ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(patientRepositoryProvider);
  final therapistRepo = ref.watch(therapistRepositoryProvider);
  return AssessmentNotifier(repo, therapistRepo, user?.uid ?? '');
});
