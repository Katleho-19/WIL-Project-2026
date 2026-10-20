//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'base_view_model.dart';

/// Which bottom-navigation tab is selected (Home, Applications, Alerts, Profile).
class ShellNavViewModel extends BaseViewModel {
  int index = 0;

  void setIndex(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
