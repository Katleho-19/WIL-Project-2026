//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: school_info.dart stores the fixed school details (name, contact, banking details,
// enrolment fee and upload size limit) that the app displays to parents.

///
/// SchoolInfo (class) - static-only constants; the private constructor SchoolInfo._() prevents instances.
class SchoolInfo {
  SchoolInfo._();

  /// General school identity shown in headers and letters.
  static const String name = 'Phehello Secondary School';
  static const String motto = 'Perseverance is the Mother of Success';

  /// enrolmentFee - the amount (in rand) the parent must pay and prove with a proof of payment.
  static const double enrolmentFee = 200.00;

  /// Banking details displayed on the payment information step so parents can pay by EFT/deposit.
  static const String accountName = 'Phehello Secondary School';
  static const String bank = 'First National Bank';
  static const String accountNumber = '53183741588';
  static const String branch = 'Odendaalsrus';
  static const String branchCode = '230335';
  static const String accountType = 'Cheque Account';

  // From the school's enrolment form header.
  /// Contact details shown on the help/support screen.
  static const String telephone = '057 101 0296';
  static const String address = '645 Makakane Street, Odendaalsrus, 9480';

  /// maxFileBytes - the largest file a parent may upload: 5 * 1024 * 1024 = 5 MB.
  static const int maxFileBytes = 5 * 1024 * 1024;
}
