import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  group('Debouncer', () {
    late Debouncer debouncer;

    setUp(() {
      debouncer = Debouncer(delay: const Duration(milliseconds: 100));
    });

    tearDown(() {
      debouncer.dispose();
    });

    test('should execute callback after delay', () async {
      var callCount = 0;

      debouncer.call(() {
        callCount++;
      });

      expect(callCount, 0);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should cancel previous timer when called multiple times', () async {
      var callCount = 0;

      debouncer.call(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      debouncer.call(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should execute callback with parameter', () async {
      String? receivedParameter;

      debouncer.callWithParameter<String>('test', (parameter) {
        receivedParameter = parameter;
      });

      await Future.delayed(const Duration(milliseconds: 150));
      expect(receivedParameter, 'test');
    });

    test('should execute async callback', () async {
      var callCount = 0;

      debouncer.callAsync(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      expect(callCount, 1);
    });

    test('should execute async callback with parameter', () async {
      int? receivedParameter;

      debouncer.callAsyncWithParameter<int>(42, (parameter) async {
        await Future.delayed(const Duration(milliseconds: 10));
        receivedParameter = parameter;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      expect(receivedParameter, 42);
    });

    test('should cancel pending execution', () async {
      var callCount = 0;

      debouncer.call(() {
        callCount++;
      });

      expect(debouncer.isActive, true);
      debouncer.cancel();
      expect(debouncer.isActive, false);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);
    });

    test('should report active state correctly', () async {
      expect(debouncer.isActive, false);

      debouncer.call(() {});
      expect(debouncer.isActive, true);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(debouncer.isActive, false);
    });

    test('should dispose correctly', () async {
      var callCount = 0;

      debouncer.call(() {
        callCount++;
      });

      debouncer.dispose();
      expect(debouncer.isActive, false);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);
    });

    test('should handle rapid successive calls', () async {
      var callCount = 0;

      for (int i = 0; i < 10; i++) {
        debouncer.call(() {
          callCount++;
        });
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should work with different delay durations', () async {
      final shortDebouncer = Debouncer(delay: const Duration(milliseconds: 50));
      final longDebouncer = Debouncer(delay: const Duration(milliseconds: 200));

      var shortCallCount = 0;
      var longCallCount = 0;

      shortDebouncer.call(() {
        shortCallCount++;
      });

      longDebouncer.call(() {
        longCallCount++;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(shortCallCount, 1);
      expect(longCallCount, 0);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(longCallCount, 1);

      shortDebouncer.dispose();
      longDebouncer.dispose();
    });
  });
}
