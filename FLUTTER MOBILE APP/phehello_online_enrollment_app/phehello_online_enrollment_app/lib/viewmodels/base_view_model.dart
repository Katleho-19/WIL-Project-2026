import 'package:flutter/foundation.dart';

/// Base class for every ViewModel.
///
/// Async work (network calls, file picking) can finish after the screen that
/// started it has been closed. Notifying a disposed [ChangeNotifier] throws, so
/// this base class silently ignores notifications after [dispose]. That is what
/// lets ViewModels run async commands without the View checking `mounted`.
abstract class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
