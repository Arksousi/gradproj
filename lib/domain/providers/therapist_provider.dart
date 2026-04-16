// therapist_provider.dart
// Riverpod providers for therapist data and AI summary state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/groq_service.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/therapist_model.dart';
import '../usecases/summarize_usecase.dart';
import 'auth_provider.dart';
import 'patient_provider.dart';

// --- Therapist stream provider ---

/// Watches the current therapist's Firestore document in real time.
final currentTherapistProvider =
    StreamProvider.autoDispose<TherapistModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.watchTherapist(user.uid);
});

/// Streams the list of patients assigned to the current therapist.
final therapistPatientsProvider =
    StreamProvider.autoDispose<List<PatientModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(patientRepositoryProvider);
  return repo.watchPatientsForTherapist(user.uid);
});

// --- AI Summary state ---

/// Holds the state of the AI summary generation for a specific patient.
class AiSummaryState {
  final String? summary;
  final bool isLoading;
  final String? errorMessage;

  const AiSummaryState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  AiSummaryState copyWith({
    String? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return AiSummaryState(
      summary: clearSummary ? null : summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AiSummaryNotifier extends StateNotifier<AiSummaryState> {
  final SummarizeUseCase _summarizeUseCase;

  AiSummaryNotifier()
      : _summarizeUseCase = SummarizeUseCase(),
        super(const AiSummaryState());

  /// Calls the Groq API to generate a summary for [patient].
  /// [apiKey] should be provided securely by the caller.
  Future<void> summarize({
    required PatientModel patient,
    required String apiKey,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSummary: true);
    try {
      final summary = await _summarizeUseCase(SummarizeParams(
        groqApiKey: apiKey,
        assessmentAnswers: patient.assessment,
        patientDescription: patient.description,
      ));
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const AiSummaryState();
  }
}

/// Provider for [AiSummaryNotifier] — auto-disposed when screen leaves.
final aiSummaryProvider =
    StateNotifierProvider.autoDispose<AiSummaryNotifier, AiSummaryState>(
        (ref) {
  return AiSummaryNotifier();
});

/// Convenience provider for the Groq service singleton.
final groqServiceProvider = Provider<GroqService>((ref) {
  return GroqService.instance;
});
