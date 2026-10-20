import 'package:flutter_test/flutter_test.dart';
import 'package:phehello_online_enrollment_app/viewmodels/base_view_model.dart';
import 'package:phehello_online_enrollment_app/viewmodels/shell_nav_view_model.dart';

class _Counter extends BaseViewModel {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

void main() {
  group('BaseViewModel', () {
    test('notifies listeners', () {
      final vm = _Counter();
      var calls = 0;
      vm.addListener(() => calls++);
      vm.increment();
      expect(calls, 1);
      vm.dispose();
    });

    test('ignores notifications after dispose instead of throwing', () {
      final vm = _Counter()..dispose();
      expect(vm.isDisposed, isTrue);
      expect(vm.increment, returnsNormally);
    });
  });

  group('ShellNavViewModel', () {
    test('only notifies when the tab actually changes', () {
      final vm = ShellNavViewModel();
      var calls = 0;
      vm.addListener(() => calls++);
      vm.setIndex(0);
      expect(calls, 0);
      vm.setIndex(2);
      expect(vm.index, 2);
      expect(calls, 1);
    });
  });
}
