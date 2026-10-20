class ParentProfile {
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

  factory ParentProfile.fromMap(Map<String, dynamic> m) => ParentProfile(
        id: m['id'] as String,
        fullName: (m['full_name'] as String?) ?? '',
        email: m['email'] as String?,
        phoneNumber: m['phone_number'] as String?,
        relationshipToLearner: m['relationship_to_learner'] as String?,
        occupation: m['occupation'] as String?,
        role: (m['role'] as String?) ?? 'Parent',
      );

  ParentProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? relationshipToLearner,
    String? occupation,
  }) =>
      ParentProfile(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        relationshipToLearner:
            relationshipToLearner ?? this.relationshipToLearner,
        occupation: occupation ?? this.occupation,
        role: role,
      );
}
