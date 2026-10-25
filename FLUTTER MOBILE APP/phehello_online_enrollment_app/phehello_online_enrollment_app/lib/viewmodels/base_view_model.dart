//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: base_view_model.dart is the parent class of every view model. It makes sure that
// a view model which has already been disposed (its screen closed) never tries to notify its
// listeners, which would otherwise crash the app when slow async work finishes late.

import 'package:flutter/foundation.dart';

/// Base class for every ViewModel.
///
/// Async work (network calls, file picking) can finish after the screen that
/// started it has been closed. Notifying a disposed [ChangeNotifier] throws, so
/// this base class silently ignores notifications after [dispose]. That is what
/// lets ViewModels run async commands without the View checking `mounted`.
///
/// BaseViewModel (abstract class) - extends ChangeNotifier (so screens can listen for changes)
/// and adds a "disposed" safety flag. It cannot be created directly; other view models extend it.
abstract class BaseViewModel extends ChangeNotifier {
  /// _disposed - becomes true once dispose() has been called.
  bool _disposed = false;

  /// isDisposed (getter) - lets other code check whether this view model has been disposed.
  bool get isDisposed => _disposed;

  /// notifyListeners() - overrides the normal method: it tells listening widgets to rebuild only
  /// if the view model has not been disposed; after disposal the call is silently ignored.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// dispose() - overrides the normal method: marks this view model as disposed first,
  /// then lets ChangeNotifier release its resources.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
