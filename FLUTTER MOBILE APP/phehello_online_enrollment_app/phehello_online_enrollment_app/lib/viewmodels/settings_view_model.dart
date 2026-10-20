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
