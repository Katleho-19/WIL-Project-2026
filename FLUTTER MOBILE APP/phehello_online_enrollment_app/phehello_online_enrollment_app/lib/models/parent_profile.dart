//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: parent_profile.dart defines ParentProfile, the signed-in parent's account details
// (name, email, phone, relationship to the learner, occupation and role).

/// ParentProfile (class) - an immutable record of the parent's profile.
class ParentProfile {
  /// Constructor - id and fullName are required; role defaults to 'Parent'.
  const ParentProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.relationshipToLearner,
    this.occupation,
    this.role = 'Parent',
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? relationshipToLearner;
  final String? occupation;
  final String role;

  /// ParentProfile.fromMap() - factory that builds a ParentProfile from a row of the profiles table.
  /// Missing name becomes empty text and a missing role becomes 'Parent'.
  factory ParentProfile.fromMap(Map<String, dynamic> m) => ParentProfile(
    id: m['id'] as String,
    fullName: (m['full_name'] as String?) ?? '',
    email: m['email'] as String?,
    phoneNumber: m['phone_number'] as String?,
    relationshipToLearner: m['relationship_to_learner'] as String?,
    occupation: m['occupation'] as String?,
    role: (m['role'] as String?) ?? 'Parent',
  );

  /// copyWith() - returns a new ParentProfile with only the supplied editable fields changed
  /// (name, phone, relationship, occupation). The id, email and role stay the same.
  /// Used when the parent edits their personal details.
  ParentProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? relationshipToLearner,
    String? occupation,
  }) => ParentProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    relationshipToLearner: relationshipToLearner ?? this.relationshipToLearner,
    occupation: occupation ?? this.occupation,
    role: role,
  );
}
