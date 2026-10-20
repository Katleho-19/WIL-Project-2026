//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'package:shared_preferences/shared_preferences.dart';

import 'base_view_model.dart';

/// Local app preferences (Profile > Notifications ON/OFF).
class SettingsViewModel extends BaseViewModel {
  SettingsViewModel() {
    _load();
  }

  static const _key = 'notifications_enabled';
  bool notificationsEnabled = true;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool v) async {
    notificationsEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
  }
}
