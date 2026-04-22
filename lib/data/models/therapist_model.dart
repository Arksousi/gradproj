// therapist_model.dart
// Data model for a therapist's profile stored in Firestore.

/// Represents therapist profile data stored at: therapists/{uid}
class TherapistModel {
  final String uid;
  final String name;
  final String email;

  /// List of patient UIDs assigned to this therapist.
  final List<String> patients;

  final String specialization;
  final String bio;

  // Extended profile fields
  final String nationality;
  final int age;
  final int yearsOfExperience;
  final List<String> specializedFields;
  final List<String> languages;
  final List<String> sessionTypes;
  final Map<String, String> workingHours;
  final String clinicLocation;
  final String clinicMapUrl;
  final double rating;
  final int reviewCount;
  final String profileImageUrl;
  final bool isOnShift;
  final bool isAvailableForImmediate;

  const TherapistModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.patients,
    required this.specialization,
    required this.bio,
    this.nationality = '',
    this.age = 0,
    this.yearsOfExperience = 0,
    this.specializedFields = const [],
    this.languages = const [],
    this.sessionTypes = const [],
    this.workingHours = const {},
    this.clinicLocation = '',
    this.clinicMapUrl = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.profileImageUrl = '',
    this.isOnShift = false,
    this.isAvailableForImmediate = false,
  });

  // --- Serialization ---

  factory TherapistModel.fromMap(String uid, Map<String, dynamic> map) {
    return TherapistModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      patients: List<String>.from(
          (map['patients'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      specialization: map['specialization'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      nationality: map['nationality'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toInt() ?? 0,
      specializedFields: List<String>.from(
          (map['specializedFields'] as List<dynamic>?)
                  ?.map((e) => e.toString()) ??
              []),
      languages: List<String>.from(
          (map['languages'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      sessionTypes: List<String>.from(
          (map['sessionTypes'] as List<dynamic>?)?.map((e) => e.toString()) ??
              []),
      workingHours: Map<String, String>.from(
          (map['workingHours'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())) ??
              {}),
      clinicLocation: map['clinicLocation'] as String? ?? '',
      clinicMapUrl: map['clinicMapUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      isOnShift: map['isOnShift'] as bool? ?? false,
      isAvailableForImmediate: map['isAvailableForImmediate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'patients': patients,
      'specialization': specialization,
      'bio': bio,
      'nationality': nationality,
      'age': age,
      'yearsOfExperience': yearsOfExperience,
      'specializedFields': specializedFields,
      'languages': languages,
      'sessionTypes': sessionTypes,
      'workingHours': workingHours,
      'clinicLocation': clinicLocation,
      'clinicMapUrl': clinicMapUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'profileImageUrl': profileImageUrl,
      'isOnShift': isOnShift,
      'isAvailableForImmediate': isAvailableForImmediate,
    };
  }

  TherapistModel copyWith({
    String? name,
    String? email,
    List<String>? patients,
    String? specialization,
    String? bio,
    String? nationality,
    int? age,
    int? yearsOfExperience,
    List<String>? specializedFields,
    List<String>? languages,
    List<String>? sessionTypes,
    Map<String, String>? workingHours,
    String? clinicLocation,
    String? clinicMapUrl,
    double? rating,
    int? reviewCount,
    String? profileImageUrl,
    bool? isOnShift,
    bool? isAvailableForImmediate,
  }) {
    return TherapistModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      patients: patients ?? this.patients,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specializedFields: specializedFields ?? this.specializedFields,
      languages: languages ?? this.languages,
      sessionTypes: sessionTypes ?? this.sessionTypes,
      workingHours: workingHours ?? this.workingHours,
      clinicLocation: clinicLocation ?? this.clinicLocation,
      clinicMapUrl: clinicMapUrl ?? this.clinicMapUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnShift: isOnShift ?? this.isOnShift,
      isAvailableForImmediate:
          isAvailableForImmediate ?? this.isAvailableForImmediate,
    );
  }

  @override
  String toString() =>
      'TherapistModel(uid: $uid, name: $name, patients: ${patients.length})';
}
