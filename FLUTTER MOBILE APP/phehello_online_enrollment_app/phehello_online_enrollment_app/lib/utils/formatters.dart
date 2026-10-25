//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: formatters.dart contains small helpers that convert raw values (database dates,
// numbers, file sizes, ID numbers) into text that is shown on screen or saved to the database.

import 'package:intl/intl.dart';

/// Formatters (class) - static-only helpers; the private constructor Formatters._() prevents instances.
class Formatters {
  Formatters._();

  /// parseDate() - converts a database value into a DateTime (date only, no time-zone change).
  /// Returns null if the value is null or cannot be parsed.
  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// parseDateTime() - converts a database timestamp into a DateTime in the phone's local time zone.
  /// Returns null if the value is null or cannot be parsed.
  static DateTime? parseDateTime(dynamic v) {
    if (v == null) return null;
    final d = DateTime.tryParse(v.toString());
    return d?.toLocal();
  }

  /// shortDate() - formats a date like "5 Oct 2026".
  static String shortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  /// longDate() - formats a date like "5 October 2026".
  static String longDate(DateTime d) => DateFormat('d MMMM yyyy').format(d);

  /// dateTimeLabel() - friendly label for lists: "Today • 10:24" or "Yesterday • 14:32" for
  /// recent items, otherwise the short date. It compares calendar days (ignoring the time of day).
  /// "Today • 10:24", "Yesterday • 14:32" or "24 Aug 2026".
  static String dateTimeLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    final time = DateFormat('HH:mm').format(d);
    if (diff == 0) return 'Today • $time';
    if (diff == 1) return 'Yesterday • $time';
    return shortDate(d);
  }

  /// money() - formats an amount as South African rand with thousands separators and two
  /// decimals, e.g. "R 1,200.00".
  static String money(double v) => 'R ${NumberFormat('#,##0.00').format(v)}';

  /// fileSize() - turns a byte count into "x B", "x.x KB" or "x.x MB" depending on its size.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// greeting() - returns "Good morning," before 12:00, "Good afternoon," before 18:00,
  /// otherwise "Good evening,", based on the current hour.
  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// maskId() - hides an ID number for privacy by replacing all but the last 3 characters with
  /// asterisks. Returns "-" if the ID is missing/empty and the ID unchanged if it has 3 or fewer characters.
  /// Hides all but the last 3 characters of an ID number.
  static String maskId(String? id) {
    if (id == null || id.isEmpty) return '-';
    if (id.length <= 3) return id;
    return '${'*' * (id.length - 3)}${id.substring(id.length - 3)}';
  }

  /// isoDate() - formats a date as "yyyy-MM-dd", the format the database date columns expect.
  /// ISO date (yyyy-MM-dd) for database date columns.
  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// displayDate() - formats a date as "dd / MM / yyyy" for date fields on the forms.
  static String displayDate(DateTime d) =>
      DateFormat('dd / MM / yyyy').format(d);
}
