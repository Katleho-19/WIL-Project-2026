import '../utils/formatters.dart';

class Learner {
  const Learner({
    required this.id,
    required this.firstName,
    required this.surname,
    this.middleName,
    this.initials,
    this.otherNames,
    this.idNumber,
    this.dateOfBirth,
    this.gender,
    this.studentNumber,
    this.previousSchoolName,
    this.highestGradePassed,
    this.yearGradePassed,
    this.schoolHistoryNotes,
  });

  final String id;
  final String firstName;
  final String surname;
  final String? middleName;
  final String? initials;
  final String? otherNames;
  final String? idNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? studentNumber;
  final String? previousSchoolName;
  final String? highestGradePassed;
  final String? yearGradePassed;
  final String? schoolHistoryNotes;

  String get fullName {
    final parts = [firstName, middleName ?? '', surname]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  factory Learner.fromMap(Map<String, dynamic> m) => Learner(
        id: (m['learner_id'] ?? m['id'] ?? '') as String,
        firstName: (m['first_name'] as String?) ?? '',
        surname: (m['surname'] as String?) ?? '',
        middleName: m['middle_name'] as String?,
        initials: m['initials'] as String?,
        otherNames: m['other_names'] as String?,
        idNumber: m['id_number'] as String?,
        dateOfBirth: Formatters.parseDate(m['date_of_birth']),
        gender: m['gender'] as String?,
        studentNumber: m['student_number'] as String?,
        previousSchoolName: m['previous_school_name'] as String?,
        highestGradePassed: m['highest_grade_passed'] as String?,
        yearGradePassed: m['year_grade_passed']?.toString(),
        schoolHistoryNotes: m['school_history_notes'] as String?,
      );
}

class LearnerMedicalInfo {
  const LearnerMedicalInfo({
    this.medicalAidName,
    this.medicalAidNumber,
    this.medicalAidMainMember,
    this.doctorName,
    this.doctorAddress,
    this.siblingsAtSchool,
  });

  final String? medicalAidName;
  final String? medicalAidNumber;
  final String? medicalAidMainMember;
  final String? doctorName;
  final String? doctorAddress;
  final String? siblingsAtSchool;

  factory LearnerMedicalInfo.fromMap(Map<String, dynamic> m) =>
      LearnerMedicalInfo(
        medicalAidName: m['medical_aid_name'] as String?,
        medicalAidNumber: m['medical_aid_number'] as String?,
        medicalAidMainMember: m['medical_aid_main_member'] as String?,
        doctorName: m['doctor_name'] as String?,
        doctorAddress: m['doctor_address'] as String?,
        siblingsAtSchool: m['siblings_at_school'] as String?,
      );
}
