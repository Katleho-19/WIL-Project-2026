//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: enrolment_draft.dart defines EnrolmentDraft, the set of text answers a parent has
// typed into the six-step enrolment wizard. It can be turned into JSON text so an unfinished
// application can be saved on the device ("Save & close") and restored later.

import 'dart:convert';

/// Text answers collected by the six-step enrolment wizard.
/// (Files are kept separately in memory.) Saved locally as a draft.
///
/// EnrolmentDraft (class) - a mutable bag of form answers; each field starts empty and is
/// filled in as the parent completes the steps.
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

  /// learnerName (getter) - the learner's first name and surname joined together and trimmed;
  /// used to label the saved draft.
  String get learnerName => '$firstName $surname'.trim();

  /// isEmpty (getter) - true if the key fields (first name, surname, grade, guardian name) are all
  /// empty, meaning there is nothing worth saving as a draft.
  bool get isEmpty =>
      firstName.isEmpty &&
      surname.isEmpty &&
      gradeApplied.isEmpty &&
      guardianName.isEmpty;

  /// toJson() - converts every answer (plus the current step and save time) into a Map that can
  /// be turned into JSON. Dates are written as ISO-8601 text.
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

  /// encode() - turns the draft into a single JSON string so it can be stored on the device.
  String encode() => jsonEncode(toJson());

  /// decode() - rebuilds an EnrolmentDraft from a saved JSON string.
  /// A small inner helper s() reads a text value (or '' if missing); dates are parsed back
  /// with DateTime.tryParse and the step number is read as an int (default 0).
  /// If the stored text is corrupt, the error is ignored and a fresh draft is returned.
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
