//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: uuid.dart provides a small function that generates random unique identifiers
// (UUID version 4), used to give uploaded files and records unique names.

import 'dart:math';

/// Minimal RFC 4122 version-4 UUID generator.
///
/// generateUuidV4() - creates a random UUID such as "3f2b8c1e-...-9a4d".
/// Steps: (1) get a cryptographically secure random generator; (2) fill 16 random bytes;
/// (3) set the version bits (byte 6 becomes 0x4_) and the variant bits (byte 8 becomes 0b10______)
/// as the UUID v4 standard requires; (4) h() converts one byte to two hex characters;
/// (5) join the bytes in the 8-4-4-4-12 pattern separated by hyphens.
String generateUuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
