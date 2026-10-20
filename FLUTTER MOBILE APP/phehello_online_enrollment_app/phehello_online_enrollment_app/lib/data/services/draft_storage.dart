//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034


import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enrolment_draft.dart';

/// Saves / restores the in-progress enrolment form on the device
/// ("save and continue later"). Only text answers are stored locally.
class DraftStorage {
  static String _key(String userId) => 'enrolment_draft_$userId';

  Future<EnrolmentDraft?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    return EnrolmentDraft.decode(raw);
  }

  Future<void> save(String userId, EnrolmentDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    draft.savedAt = DateTime.now();
    await prefs.setString(_key(userId), draft.encode());
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
