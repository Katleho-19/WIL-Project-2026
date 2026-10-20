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
