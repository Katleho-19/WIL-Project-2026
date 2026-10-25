//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: settings_view_model.dart stores the parent's local app settings on the device.
// At the moment that is the Notifications ON/OFF switch on the Profile screen.

import 'package:shared_preferences/shared_preferences.dart';

import 'base_view_model.dart';

/// Local app preferences (Profile > Notifications ON/OFF).
///
/// SettingsViewModel (class) - loads and saves the notifications setting using SharedPreferences.
class SettingsViewModel extends BaseViewModel {
  /// Constructor - immediately starts loading the saved setting from the device.
  SettingsViewModel() {
    _load();
  }

  /// _key - the name under which the setting is stored on the device.
  static const _key = 'notifications_enabled';

  /// notificationsEnabled - true when notifications are switched on (the default).
  bool notificationsEnabled = true;

  /// _load() - private method that reads the saved value (defaulting to true if none is saved)
  /// and notifies listeners so the switch shows the right position.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  /// setNotificationsEnabled() - updates the switch immediately (so the UI responds at once),
  /// then saves the new value to the device.
  Future<void> setNotificationsEnabled(bool v) async {
    notificationsEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
  }
}
