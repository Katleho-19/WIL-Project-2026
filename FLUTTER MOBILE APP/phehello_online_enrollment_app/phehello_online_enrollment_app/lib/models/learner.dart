//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: learner.dart defines the data classes for the child being enrolled: Learner
// (personal and school-history details) and LearnerMedicalInfo (medical aid, doctor, siblings).

import '../utils/formatters.dart';

/// Learner (class) - an immutable record of the learner's personal and previous-school details.
class Learner {
  /// Constructor - id, firstName and surname are required; all other details are optional.
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

  /// fullName (getter) - joins first name, middle name and surname with spaces,
  /// skipping any part that is empty.
  String get fullName {
    final parts = [
      firstName,
      middleName ?? '',
      surname,
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(' ');
  }

  /// Learner.fromMap() - factory that builds a Learner from a database row (a Map).
  /// It reads the snake_case column names, uses empty text where required values are missing,
  /// and converts the date of birth and the year passed into the right types.
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

/// LearnerMedicalInfo (class) - an immutable record of the learner's medical aid, doctor
/// and siblings-at-school details. Every field is optional.
class LearnerMedicalInfo {
  /// Constructor - all medical fields are optional named parameters.
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

  /// LearnerMedicalInfo.fromMap() - factory that builds the medical record from a database row
  /// by reading each snake_case column.
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
