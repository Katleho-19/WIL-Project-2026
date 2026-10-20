//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034


/// Stakeholder-confirmed school information (SRS FR15, WhatsApp 21 Sep 2026
/// and the school's printed banking-details sheet). The system does NOT
/// process payments; it only displays these details.
class SchoolInfo {
  SchoolInfo._();

  static const String name = 'Phehello Secondary School';
  static const String motto = 'Perseverance is the Mother of Success';
  static const double enrolmentFee = 200.00;

  static const String accountName = 'Phehello Secondary School';
  static const String bank = 'First National Bank';
  static const String accountNumber = '53183741588';
  static const String branch = 'Odendaalsrus';
  static const String branchCode = '230335';
  static const String accountType = 'Cheque Account';

  // From the school's enrolment form header.
  static const String telephone = '057 101 0296';
  static const String address = '645 Makakane Street, Odendaalsrus, 9480';

  static const int maxFileBytes = 5 * 1024 * 1024;
}
