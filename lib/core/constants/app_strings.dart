// app_strings.dart
// Centralizes all user-facing strings to support easy localization.

/// All static string constants used in PsyCare.
class AppStrings {
  AppStrings._(); // Prevent instantiation

  // --- App ---
  static const String appName = 'PsyCare';
  static const String appTagline = 'Your Mental Wellness Companion';

  // --- Auth ---
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? ";
  static const String hasAccount = 'Already have an account? ';
  static const String rolePatient = 'Patient';
  static const String roleTherapist = 'Therapist';
  static const String selectRole = 'I am a...';
  static const String loginSuccess = 'Welcome back!';
  static const String registerSuccess = 'Account created successfully!';
  static const String logout = 'Log Out';

  // --- Validation ---
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String nameRequired = 'Name is required';
  static const String passwordsMismatch = 'Passwords do not match';

  // --- Patient ---
  static const String patientDashboard = 'My Dashboard';
  static const String startAssessment = 'Start Assessment';
  static const String continueAssessment = 'Continue Assessment';
  static const String assessmentTitle = 'Mental Health Assessment';
  static const String assessmentSubtitle =
      'Answer honestly — this helps your therapist understand you better.';
  static const String descriptionTitle = 'How are you feeling?';
  static const String descriptionHint =
      'Describe your feelings, thoughts, or anything on your mind...';
  static const String submitAssessment = 'Submit to Therapist';
  static const String assessmentSubmitted = 'Assessment submitted successfully!';
  static const String questionOf = 'Question';
  static const String of = 'of';

  // --- Therapist ---
  static const String therapistDashboard = 'Therapist Dashboard';
  static const String myPatients = 'My Patients';
  static const String patientDetail = 'Patient Details';
  static const String assessmentAnswers = 'Assessment Answers';
  static const String patientDescription = 'Patient Description';
  static const String summarizeWithAI = 'Summarize with AI';
  static const String aiSummary = 'AI Summary';
  static const String generating = 'Generating summary...';
  static const String noPatients = 'No patients assigned yet.';

  // --- General ---
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String finish = 'Finish';
  static const String submit = 'Submit';
  static const String welcome = 'Welcome';
  static const String hello = 'Hello';
  static const String notAvailable = 'N/A';
}
