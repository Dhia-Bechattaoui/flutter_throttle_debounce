import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  group('Throttler', () {
    late Throttler throttler;

    setUp(() {
      throttler = Throttler(interval: const Duration(milliseconds: 100));
    });

    tearDown(() {
      throttler.dispose();
    });

    test('should execute callback immediately on first call', () {
      var callCount = 0;

      throttler.call(() {
        callCount++;
      });

      expect(callCount, 1);
    });

    test('should throttle subsequent calls', () async {
      var callCount = 0;

      // First call should execute immediately
      throttler.call(() {
        callCount++;
      });
      expect(callCount, 1);

      // Second call should be throttled
      throttler.call(() {
        callCount++;
      });
      expect(callCount, 1);

      // Wait for throttle interval to pass
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 2);
    });

    test('should execute callback with parameter', () async {
      String? receivedParameter;

      throttler.callWithParameter<String>('test', (parameter) {
        receivedParameter = parameter;
      });

      expect(receivedParameter, 'test');
    });

    test('should execute async callback', () async {
      var callCount = 0;

      throttler.callAsync(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      expect(callCount, 0); // Async, so not executed yet
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 1);
    });

    test('should execute async callback with parameter', () async {
      int? receivedParameter;

      throttler.callAsyncWithParameter<int>(42, (parameter) async {
        await Future.delayed(const Duration(milliseconds: 10));
        receivedParameter = parameter;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(receivedParameter, 42);
    });

    test('should cancel pending execution', () async {
      var callCount = 0;

      // First call executes immediately
      throttler.call(() {
        callCount++;
      });
      expect(callCount, 1);

      // Second call is scheduled
      throttler.call(() {
        callCount++;
      });

      throttler.cancel();
      expect(throttler.isActive, false);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1); // Second call was cancelled
    });

    test('should report active state correctly', () async {
      expect(throttler.isActive, false);

      // First call executes immediately
      throttler.call(() {});
      expect(throttler.isActive, false);

      // Second call gets scheduled
      throttler.call(() {});
      expect(throttler.isActive, true);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(throttler.isActive, false);
    });

    test('should reset state correctly', () async {
      var callCount = 0;

      // First call executes immediately
      throttler.call(() {
        callCount++;
      });
      expect(callCount, 1);

      throttler.reset();

      // Next call should execute immediately after reset
      throttler.call(() {
        callCount++;
      });
      expect(callCount, 2);
    });

    test('should calculate time until next execution correctly', () async {
      expect(throttler.timeUntilNextExecution, Duration.zero);

      // First call executes immediately
      throttler.call(() {});

      final timeUntilNext = throttler.timeUntilNextExecution;
      expect(timeUntilNext.inMilliseconds, greaterThan(50));
      expect(timeUntilNext.inMilliseconds, lessThanOrEqualTo(100));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(throttler.timeUntilNextExecution, Duration.zero);
    });

    test('should handle rapid successive calls correctly', () async {
      var callCount = 0;

      // First call executes immediately
      for (int i = 0; i < 10; i++) {
        throttler.call(() {
          callCount++;
        });
      }

      expect(callCount, 1); // Only first call executed

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 2); // Last call executed after interval
    });

    test('should work with different interval durations', () async {
      final shortThrottler = Throttler(
        interval: const Duration(milliseconds: 50),
      );
      final longThrottler = Throttler(
        interval: const Duration(milliseconds: 200),
      );

      var shortCallCount = 0;
      var longCallCount = 0;

      // Both execute immediately
      shortThrottler.call(() {
        shortCallCount++;
      });
      longThrottler.call(() {
        longCallCount++;
      });

      expect(shortCallCount, 1);
      expect(longCallCount, 1);

      // Both get a second call
      shortThrottler.call(() {
        shortCallCount++;
      });
      longThrottler.call(() {
        longCallCount++;
      });

      await Future.delayed(const Duration(milliseconds: 75));
      expect(shortCallCount, 2); // Short interval completed
      expect(longCallCount, 1); // Long interval still pending

      await Future.delayed(const Duration(milliseconds: 150));
      expect(longCallCount, 2); // Long interval completed

      shortThrottler.dispose();
      longThrottler.dispose();
    });

    test('should dispose correctly', () async {
      var callCount = 0;

      throttler.call(() {
        callCount++;
      });

      throttler.call(() {
        callCount++;
      });

      throttler.dispose();
      expect(throttler.isActive, false);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1); // Only the first immediate call
    });
  });
}
