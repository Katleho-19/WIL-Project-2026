//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: shell_nav_view_model.dart remembers which bottom-navigation tab is currently
// selected in the main app shell.

import 'base_view_model.dart';

/// Which bottom-navigation tab is selected (Home, Applications, Alerts, Profile).
///
/// ShellNavViewModel (class) - holds the selected tab index and notifies the shell when it changes.
class ShellNavViewModel extends BaseViewModel {
  /// index - the selected tab (0 = Home, 1 = Applications, 2 = Alerts, 3 = Profile).
  int index = 0;

  /// setIndex() - switches to tab 'i'. Does nothing if that tab is already selected;
  /// otherwise saves the new index and notifies listeners so the screen updates.
  void setIndex(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
