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
