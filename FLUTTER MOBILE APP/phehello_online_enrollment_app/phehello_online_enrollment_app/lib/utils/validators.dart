//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: validators.dart contains the form-field validation rules. Each validator returns
// null when the value is acceptable, or a plain-language error message to show under the field.

/// Form validators with plain-language messages for parents/guardians (NFR4).
///
/// Validators (class) - static-only helpers; the private constructor Validators._() prevents instances.
class Validators {
  Validators._();

  /// required() - fails if the value is null or only spaces. The message can be customised.
  static String? required(
    String? v, [
    String message = 'This field is required.',
  ]) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  /// name() - validates a person's name; 'label' is the field name used in the message
  /// (e.g. "first name"). Fails if empty, shorter than 2 characters, or containing digits.
  static String? name(String? v, String label) {
    if (v == null || v.trim().isEmpty) return 'Please enter $label.';
    if (v.trim().length < 2) return 'Please enter a valid $label.';
    if (RegExp(r'[0-9]').hasMatch(v)) {
      return '$label should not contain numbers.';
    }
    return null;
  }

  /// email() - fails if empty or not shaped like text@text.text (no spaces, one "@", a dot after it).
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty)
      return 'Please enter your email address.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok
        ? null
        : 'Please enter a valid email address, e.g. name@example.com.';
  }

  /// password() - for registration/change password: fails if empty or shorter than 8 characters.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password.';
    if (v.length < 8) return 'Your password must be at least 8 characters.';
    return null;
  }

  /// loginPassword() - for the login form: only checks that something was typed
  /// (the length rule is not applied to existing accounts).
  static String? loginPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password.';
    return null;
  }

  /// confirmPassword() - fails if empty or if it does not exactly match the original password.
  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password.';
    if (v != original) return 'The two passwords do not match.';
    return null;
  }

  /// phone() - validates a South African phone number. Spaces, hyphens and brackets are removed
  /// first; the result must be 0 + 9 digits, +27 + 9 digits, or 27 + 9 digits.
  /// South African phone numbers: 0XXXXXXXXX or +27XXXXXXXXX.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a contact number.';
    final cleaned = v.replaceAll(RegExp(r'[\s\-()]'), '');
    final ok = RegExp(r'^(0\d{9}|\+27\d{9}|27\d{9})$').hasMatch(cleaned);
    return ok ? null : 'Please enter a valid phone number, e.g. 082 123 4567.';
  }

  /// idOrPassport() - validates the learner's identity number. Spaces are removed first.
  /// If it is all digits it must be exactly 13 digits, with a month (digits 3-4) between 01-12 and
  /// a day (digits 5-6) between 01-31. Otherwise it is treated as a passport number and must be
  /// 6-15 letters/digits.
  /// 13-digit South African ID number or a passport number (6-15 letters/digits).
  static String? idOrPassport(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "Please enter the learner's ID or passport number.";
    }
    final s = v.replaceAll(' ', '');
    if (RegExp(r'^\d+$').hasMatch(s)) {
      if (s.length != 13) {
        return 'A South African ID number has 13 digits. Please check it.';
      }
      final mm = int.tryParse(s.substring(2, 4)) ?? 0;
      final dd = int.tryParse(s.substring(4, 6)) ?? 0;
      if (mm < 1 || mm > 12 || dd < 1 || dd > 31) {
        return 'This ID number does not look right. Please check it.';
      }
      return null;
    }
    if (!RegExp(r'^[A-Za-z0-9]{6,15}$').hasMatch(s)) {
      return 'Please enter a valid ID or passport number.';
    }
    return null;
  }

  /// yearPassed() - optional field: empty is allowed. If filled, it must be a 4-digit year
  /// between 2000 and the current year.
  static String? yearPassed(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final y = int.tryParse(v.trim());
    final now = DateTime.now().year;
    if (y == null || v.trim().length != 4 || y < 2000 || y > now) {
      return 'Please enter a 4-digit year, e.g. $now.';
    }
    return null;
  }

  /// paymentReference() - fails if empty or shorter than 3 characters.
  static String? paymentReference(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter the payment reference you used.';
    }
    if (v.trim().length < 3) return 'The payment reference is too short.';
    return null;
  }

  /// amount() - fails if empty or if parseAmount() cannot read it as a number greater than 0.
  static String? amount(String? v) {
    if (v == null || v.trim().isEmpty)
      return 'Please enter the amount you paid.';
    final n = parseAmount(v);
    if (n == null || n <= 0) return 'Please enter a valid amount, e.g. 200.00.';
    return null;
  }

  /// parseAmount() - converts typed text into a number: removes "R" and spaces and treats a
  /// comma as a decimal point (so "R 200,00" becomes 200.0). Returns null if it is not a number.
  static double? parseAmount(String v) {
    final cleaned = v
        .replaceAll('R', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}
