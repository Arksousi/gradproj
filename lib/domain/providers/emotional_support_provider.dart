// emotional_support_provider.dart
// State machine for the 5-step AI Emotional Support flow inside DescriptionScreen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_keys.dart';
import '../../core/services/groq_service.dart';
import '../../data/repositories/patient_repository.dart';
import 'auth_provider.dart';
import 'patient_provider.dart';

const _kGroqApiKey = kGroqApiKey;

enum SupportStep {
  input,                // Patient is typing
  loadingWelcome,       // Groq call 1 in flight
  welcome,              // Welcome bubble shown; comfort fetch pending
  loadingComfort,       // Groq call 2 in flight (emotional analysis)
  comfort,              // Comfort bubble shown; help question pending / answered
  selectMethod,         // Method cards shown (wantedHelp == true)
  loadingMethod,        // Groq call 3 in flight
  showMethod,           // Method response shown; reactions pending / answered
  loadingNoHelpClosing, // Groq call for declined-help closing
  noHelpClosing,        // AI closing bubble shown; Continue visible
  loadingStruggling,    // Groq call for "still struggling" closing
  strugglingDone,       // AI struggling response shown; Continue visible
  done,                 // Reaction saved; Continue button visible
}

class EmotionalSupportState {
  final SupportStep step;
  final String? welcomeResponse;
  final String? comfortResponse;    // emotional analysis & comfort (step 2)
  final String? secondMessage;      // patient's typed follow-up response
  final bool? wantedHelp;           // null = not yet answered
  final String? selectedMethod;     // 'breathing' | 'meditation' | 'reframing' | 'quotes'
  final String? methodResponse;
  final String? closingReaction;
  final String? noHelpResponse;     // AI closing when patient declines help
  final String? strugglingResponse; // AI closing when patient still struggles
  final bool isSaving;

  const EmotionalSupportState({
    this.step = SupportStep.input,
    this.welcomeResponse,
    this.comfortResponse,
    this.secondMessage,
    this.wantedHelp,
    this.selectedMethod,
    this.methodResponse,
    this.closingReaction,
    this.noHelpResponse,
    this.strugglingResponse,
    this.isSaving = false,
  });

  EmotionalSupportState copyWith({
    SupportStep? step,
    String? welcomeResponse,
    String? comfortResponse,
    String? secondMessage,
    bool? wantedHelp,
    String? selectedMethod,
    String? methodResponse,
    String? closingReaction,
    String? noHelpResponse,
    String? strugglingResponse,
    bool? isSaving,
  }) {
    return EmotionalSupportState(
      step: step ?? this.step,
      welcomeResponse: welcomeResponse ?? this.welcomeResponse,
      comfortResponse: comfortResponse ?? this.comfortResponse,
      secondMessage: secondMessage ?? this.secondMessage,
      wantedHelp: wantedHelp ?? this.wantedHelp,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      methodResponse: methodResponse ?? this.methodResponse,
      closingReaction: closingReaction ?? this.closingReaction,
      noHelpResponse: noHelpResponse ?? this.noHelpResponse,
      strugglingResponse: strugglingResponse ?? this.strugglingResponse,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class EmotionalSupportNotifier
    extends StateNotifier<EmotionalSupportState> {
  final GroqService _groq;
  final PatientRepository _repo;
  final String _uid;

  EmotionalSupportNotifier(this._groq, this._repo, this._uid)
      : super(const EmotionalSupportState());

  // ── Step 1 ────────────────────────────────────────────────────────────────

  Future<void> sendWelcomeRequest(String patientText) async {
    state = state.copyWith(step: SupportStep.loadingWelcome);
    try {
      final response = await _groq.getEmotionalSupportWelcome(
        apiKey: _kGroqApiKey,
        patientText: patientText,
      );
      state = state.copyWith(
        step: SupportStep.welcome,
        welcomeResponse: response,
      );
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.welcome,
        welcomeResponse:
            "I'm having trouble connecting right now. "
            "But I heard you, and your therapist will too. 💙",
      );
    }
  }

  // ── Step 1.5 ──────────────────────────────────────────────────────────────

  Future<void> submitFollowUp({
    required String firstMessage,
    required String secondMessage,
  }) async {
    state = state.copyWith(secondMessage: secondMessage, step: SupportStep.loadingComfort);
    try {
      final response = await _groq.getEmotionalComfort(
        apiKey: _kGroqApiKey,
        firstMessage: firstMessage,
        secondMessage: secondMessage,
      );
      state = state.copyWith(
        step: SupportStep.comfort,
        comfortResponse: response,
      );
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.comfort,
        comfortResponse:
            'Whatever you\'re going through right now, '
            'you don\'t have to face it alone. '
            'Reaching out the way you just did takes real courage. 💙',
      );
    }
  }

  // ── Step 2: help decision ─────────────────────────────────────────────────

  Future<void> setWantedHelp(bool wanted, {required String patientText}) async {
    if (wanted) {
      state = state.copyWith(wantedHelp: true, step: SupportStep.selectMethod);
      return;
    }
    state = state.copyWith(wantedHelp: false, step: SupportStep.loadingNoHelpClosing);
    try {
      final response = await _groq.getNoHelpClosing(
        apiKey: _kGroqApiKey,
        patientText: patientText,
      );
      state = state.copyWith(step: SupportStep.noHelpClosing, noHelpResponse: response);
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.noHelpClosing,
        noHelpResponse:
            "That's completely okay — I'm so glad you showed up today and shared what's on your heart. 💙 "
            "Sometimes, just letting it out is the most powerful thing you can do. "
            "Your therapist will have all of this context and will be ready to walk alongside you. "
            "You did something brave today. Never forget that. 🌿",
      );
    }
  }

  // ── Step 3 ────────────────────────────────────────────────────────────────

  void selectMethod(String method) {
    state = state.copyWith(selectedMethod: method);
  }

  // ── Step 4 ────────────────────────────────────────────────────────────────

  Future<void> fetchMethodGuidance(String patientText) async {
    if (state.selectedMethod == null) return;
    state = state.copyWith(step: SupportStep.loadingMethod);
    try {
      final response = await _groq.getMethodGuidance(
        apiKey: _kGroqApiKey,
        patientText: patientText,
        method: state.selectedMethod!,
      );
      state = state.copyWith(
        step: SupportStep.showMethod,
        methodResponse: response,
      );
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.showMethod,
        methodResponse:
            "I'm having trouble connecting right now. "
            "But I heard you, and your therapist will too. 💙",
      );
    }
  }

  // ── Step 5 ────────────────────────────────────────────────────────────────

  Future<void> saveAndComplete({
    required String firstMessage,
    required String reaction,
  }) async {
    state = state.copyWith(
      closingReaction: reaction,
      isSaving: true,
      step: SupportStep.done,
    );
    try {
      await _repo.saveEmotionalSupport(
        uid: _uid,
        data: {
          'firstMessage': firstMessage,
          'secondMessage': state.secondMessage ?? '',
          'comfortResponse': state.welcomeResponse ?? '',
          'bulletResponse': state.comfortResponse ?? '',
          'wantedHelp': state.wantedHelp ?? false,
          'selectedMethod': state.selectedMethod ?? '',
          'methodResponse': state.methodResponse ?? '',
          'closingReaction': reaction,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Non-fatal — continue the flow even if Firestore write fails
    }
    state = state.copyWith(isSaving: false);
  }

  // ── Still struggling ──────────────────────────────────────────────────────

  Future<void> saveAndFetchStrugglingResponse({
    required String firstMessage,
  }) async {
    state = state.copyWith(
      closingReaction: 'still_struggling',
      isSaving: true,
      step: SupportStep.loadingStruggling,
    );
    try {
      await _repo.saveEmotionalSupport(
        uid: _uid,
        data: {
          'firstMessage': firstMessage,
          'secondMessage': state.secondMessage ?? '',
          'comfortResponse': state.welcomeResponse ?? '',
          'bulletResponse': state.comfortResponse ?? '',
          'wantedHelp': state.wantedHelp ?? false,
          'selectedMethod': state.selectedMethod ?? '',
          'methodResponse': state.methodResponse ?? '',
          'closingReaction': 'still_struggling',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Non-fatal
    }
    state = state.copyWith(isSaving: false);

    try {
      final response = await _groq.getStrugglingResponse(
        apiKey: _kGroqApiKey,
        patientText: firstMessage,
      );
      state = state.copyWith(
        step: SupportStep.strugglingDone,
        strugglingResponse: response,
      );
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.strugglingDone,
        strugglingResponse:
            "Healing isn't always linear, and that's completely okay. 💙 "
            "What you did today — showing up, writing this, going through all of this — "
            "took real courage. Your therapist will see everything you shared "
            "and will be there to guide you through what comes next. "
            "You are not alone in this, not even for a moment. 🌿",
      );
    }
  }
}

final emotionalSupportProvider = StateNotifierProvider.autoDispose<
    EmotionalSupportNotifier, EmotionalSupportState>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(patientRepositoryProvider);
  return EmotionalSupportNotifier(
    GroqService.instance,
    repo,
    user?.uid ?? '',
  );
});
