//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'dart:convert';

/// Text answers collected by the six-step enrolment wizard.
/// (Files are kept separately in memory.) Saved locally as a draft.
class EnrolmentDraft {
  // Step 1 - learner
  String firstName = '';
  String middleName = '';
  String surname = '';
  String initials = '';
  String otherNames = '';
  DateTime? dateOfBirth;
  String gender = '';
  String idNumber = '';

  // Step 2 - academic
  String gradeApplied = '';
  String highestGradePassed = '';
  String yearPassed = '';
  String previousSchool = '';
  String schoolHistoryNotes = '';

  // Step 3 - medical & family
  String medicalAidName = '';
  String medicalAidNumber = '';
  String mainMember = '';
  String doctorName = '';
  String doctorAddress = '';
  String siblingsAtSchool = '';

  // Step 4 - guardian
  String guardianName = '';
  String relationship = '';
  String guardianPhone = '';
  String guardianEmail = '';

  // Step 6 - payment
  String paymentReference = '';
  String amountPaid = '';

  // Save & close bookkeeping
  int step = 0;
  DateTime? savedAt;

  String get learnerName => '$firstName $surname'.trim();

  bool get isEmpty =>
      firstName.isEmpty &&
      surname.isEmpty &&
      gradeApplied.isEmpty &&
      guardianName.isEmpty;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'middleName': middleName,
    'surname': surname,
    'initials': initials,
    'otherNames': otherNames,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'idNumber': idNumber,
    'gradeApplied': gradeApplied,
    'highestGradePassed': highestGradePassed,
    'yearPassed': yearPassed,
    'previousSchool': previousSchool,
    'schoolHistoryNotes': schoolHistoryNotes,
    'medicalAidName': medicalAidName,
    'medicalAidNumber': medicalAidNumber,
    'mainMember': mainMember,
    'doctorName': doctorName,
    'doctorAddress': doctorAddress,
    'siblingsAtSchool': siblingsAtSchool,
    'guardianName': guardianName,
    'relationship': relationship,
    'guardianPhone': guardianPhone,
    'guardianEmail': guardianEmail,
    'paymentReference': paymentReference,
    'amountPaid': amountPaid,
    'step': step,
    'savedAt': savedAt?.toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  static EnrolmentDraft decode(String source) {
    final d = EnrolmentDraft();
    try {
      final m = jsonDecode(source) as Map<String, dynamic>;
      String s(String k) => (m[k] as String?) ?? '';
      d.firstName = s('firstName');
      d.middleName = s('middleName');
      d.surname = s('surname');
      d.initials = s('initials');
      d.otherNames = s('otherNames');
      d.dateOfBirth = DateTime.tryParse(s('dateOfBirth'));
      d.gender = s('gender');
      d.idNumber = s('idNumber');
      d.gradeApplied = s('gradeApplied');
      d.highestGradePassed = s('highestGradePassed');
      d.yearPassed = s('yearPassed');
      d.previousSchool = s('previousSchool');
      d.schoolHistoryNotes = s('schoolHistoryNotes');
      d.medicalAidName = s('medicalAidName');
      d.medicalAidNumber = s('medicalAidNumber');
      d.mainMember = s('mainMember');
      d.doctorName = s('doctorName');
      d.doctorAddress = s('doctorAddress');
      d.siblingsAtSchool = s('siblingsAtSchool');
      d.guardianName = s('guardianName');
      d.relationship = s('relationship');
      d.guardianPhone = s('guardianPhone');
      d.guardianEmail = s('guardianEmail');
      d.paymentReference = s('paymentReference');
      d.amountPaid = s('amountPaid');
      d.step = (m['step'] as num?)?.toInt() ?? 0;
      d.savedAt = DateTime.tryParse(s('savedAt'));
    } catch (_) {
      // Corrupt draft: start fresh.
    }
    return d;
  }
}
