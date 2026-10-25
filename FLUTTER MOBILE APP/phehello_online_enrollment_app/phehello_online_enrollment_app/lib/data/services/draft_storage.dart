//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: draft_storage.dart saves, loads and deletes the unfinished enrolment form on the
// phone itself (using SharedPreferences) so a parent can "save and continue later".

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enrolment_draft.dart';

/// Saves / restores the in-progress enrolment form on the device
/// ("save and continue later"). Only text answers are stored locally.
///
/// DraftStorage (class) - local storage for one draft per user.
class DraftStorage {
  /// _key() - private helper that builds the storage key "enrolment_draft_<userId>", so each
  /// signed-in user has their own separate draft.
  static String _key(String userId) => 'enrolment_draft_$userId';

  /// load() - reads the saved draft for this user and decodes it into an EnrolmentDraft.
  /// Returns null if nothing has been saved.
  Future<EnrolmentDraft?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    return EnrolmentDraft.decode(raw);
  }

  /// save() - stamps the draft with the current time and stores it as JSON text for this user.
  Future<void> save(String userId, EnrolmentDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    draft.savedAt = DateTime.now();
    await prefs.setString(_key(userId), draft.encode());
  }

  /// clear() - deletes this user's saved draft (used after a successful submission or when discarding).
  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
