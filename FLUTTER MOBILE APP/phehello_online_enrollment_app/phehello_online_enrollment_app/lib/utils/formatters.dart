//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static DateTime? parseDateTime(dynamic v) {
    if (v == null) return null;
    final d = DateTime.tryParse(v.toString());
    return d?.toLocal();
  }

  static String shortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String longDate(DateTime d) => DateFormat('d MMMM yyyy').format(d);

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

  static String money(double v) => 'R ${NumberFormat('#,##0.00').format(v)}';

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// Hides all but the last 3 characters of an ID number.
  static String maskId(String? id) {
    if (id == null || id.isEmpty) return '-';
    if (id.length <= 3) return id;
    return '${'*' * (id.length - 3)}${id.substring(id.length - 3)}';
  }

  /// ISO date (yyyy-MM-dd) for database date columns.
  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String displayDate(DateTime d) => DateFormat('dd / MM / yyyy').format(d);
}
