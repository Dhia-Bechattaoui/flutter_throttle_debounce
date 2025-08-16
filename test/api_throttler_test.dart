import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  group('ApiThrottler', () {
    late ApiThrottler apiThrottler;

    setUp(() {
      apiThrottler = ApiThrottler(
        requestsPerInterval: 3,
        interval: const Duration(milliseconds: 200),
        enableQueuing: true,
        enableDeduplication: true,
      );
    });

    tearDown(() {
      apiThrottler.dispose();
    });

    test('should execute requests immediately when under limit', () async {
      var callCount = 0;

      await apiThrottler.call('test1', () async {
        callCount++;
      });

      await apiThrottler.call('test2', () async {
        callCount++;
      });

      await apiThrottler.call('test3', () async {
        callCount++;
      });

      expect(callCount, 3);
    });

    test('should queue requests when over limit', () async {
      var callCount = 0;

      // These should execute immediately
      for (int i = 0; i < 3; i++) {
        unawaited(
          apiThrottler.call('test$i', () async {
            callCount++;
          }),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(callCount, 3);

      // This should be queued
      final queuedFuture = apiThrottler.call('test4', () async {
        callCount++;
      });

      expect(callCount, 3); // Still 3, queued request not executed yet
      expect(apiThrottler.queuedRequestsCount, 1);

      // Wait for rate limit to reset
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await queuedFuture;

      expect(callCount, 4);
      expect(apiThrottler.queuedRequestsCount, 0);
    });

    test('should track requests in current interval correctly', () async {
      expect(apiThrottler.requestsInCurrentInterval, 0);
      expect(apiThrottler.remainingRequests, 3);

      await apiThrottler.call('test1', () async {});
      expect(apiThrottler.requestsInCurrentInterval, 1);
      expect(apiThrottler.remainingRequests, 2);

      await apiThrottler.call('test2', () async {});
      expect(apiThrottler.requestsInCurrentInterval, 2);
      expect(apiThrottler.remainingRequests, 1);

      await apiThrottler.call('test3', () async {});
      expect(apiThrottler.requestsInCurrentInterval, 3);
      expect(apiThrottler.remainingRequests, 0);
      expect(apiThrottler.isRateLimited, true);
    });

    test('should deduplicate identical requests', () async {
      var callCount = 0;

      // Start two identical requests simultaneously
      final future1 = apiThrottler.call('duplicate', () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        callCount++;
      });

      final future2 = apiThrottler.call('duplicate', () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        callCount++;
      });

      await Future.wait([future1, future2]);

      expect(callCount, 1); // Only one execution despite two calls
    });

    test('should handle callWithParameter correctly', () async {
      String? receivedParameter;

      await apiThrottler.callWithParameter<String>('test', 'parameter',
          (param) async {
        receivedParameter = param;
      });

      expect(receivedParameter, 'parameter');
    });

    test('should calculate time until next slot correctly', () async {
      expect(apiThrottler.timeUntilNextSlot, Duration.zero);

      // Fill up the rate limit
      for (int i = 0; i < 3; i++) {
        await apiThrottler.call('test$i', () async {});
      }

      expect(apiThrottler.isRateLimited, true);

      final timeUntilNext = apiThrottler.timeUntilNextSlot;
      expect(timeUntilNext.inMilliseconds, greaterThan(100));
      expect(timeUntilNext.inMilliseconds, lessThanOrEqualTo(200));

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(apiThrottler.timeUntilNextSlot, Duration.zero);
    });

    test('should cancel queued requests', () async {
      var callCount = 0;

      // Fill rate limit
      for (int i = 0; i < 3; i++) {
        await apiThrottler.call('test$i', () async {
          callCount++;
        });
      }

      // Queue some requests
      unawaited(
        apiThrottler.call('queued1', () async {
          callCount++;
        }),
      );

      unawaited(
        apiThrottler.call('queued2', () async {
          callCount++;
        }),
      );

      expect(apiThrottler.queuedRequestsCount, 2);

      apiThrottler.cancelQueuedRequests();
      expect(apiThrottler.queuedRequestsCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(callCount, 3); // Only the initial 3 calls
    });

    test('should reset state correctly', () async {
      // Fill rate limit
      for (int i = 0; i < 3; i++) {
        await apiThrottler.call('test$i', () async {});
      }

      expect(apiThrottler.isRateLimited, true);

      apiThrottler.reset();

      expect(apiThrottler.requestsInCurrentInterval, 0);
      expect(apiThrottler.remainingRequests, 3);
      expect(apiThrottler.isRateLimited, false);
    });

    test('should work without queuing when disabled', () async {
      final noQueueThrottler = ApiThrottler(
        requestsPerInterval: 2,
        interval: const Duration(milliseconds: 100),
        enableQueuing: false,
      );

      var callCount = 0;

      // Fill rate limit
      await noQueueThrottler.call('test1', () async {
        callCount++;
      });
      await noQueueThrottler.call('test2', () async {
        callCount++;
      });

      // This should execute immediately despite rate limit
      await noQueueThrottler.call('test3', () async {
        callCount++;
      });

      expect(callCount, 3);
      expect(noQueueThrottler.queuedRequestsCount, 0);

      noQueueThrottler.dispose();
    });

    test('should work without deduplication when disabled', () async {
      final noDedupThrottler = ApiThrottler(
        requestsPerInterval: 5,
        interval: const Duration(milliseconds: 100),
        enableDeduplication: false,
      );

      var callCount = 0;

      // Start two identical requests simultaneously
      final future1 = noDedupThrottler.call('duplicate', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      final future2 = noDedupThrottler.call('duplicate', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      await Future.wait([future1, future2]);

      expect(callCount, 2); // Both executions

      noDedupThrottler.dispose();
    });

    test('should handle errors in callbacks correctly', () async {
      var successCount = 0;
      var errorCount = 0;

      try {
        await apiThrottler.call('error-test', () async {
          throw Exception('Test error');
        });
      } on Exception {
        errorCount++;
      }

      // Should still be able to make more requests after an error
      await apiThrottler.call('success-test', () async {
        successCount++;
      });

      expect(errorCount, 1);
      expect(successCount, 1);
    });

    test('should process queue in correct order', () async {
      final executionOrder = <String>[];

      // Fill rate limit
      for (int i = 0; i < 3; i++) {
        await apiThrottler.call('initial$i', () async {
          executionOrder.add('initial$i');
        });
      }

      // Queue requests
      final futures = <Future<void>>[];
      for (int i = 0; i < 3; i++) {
        futures.add(
          apiThrottler.call('queued$i', () async {
            executionOrder.add('queued$i');
          }),
        );
      }

      // Wait for rate limit to reset and queue to process
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Future.wait(futures);

      expect(
        executionOrder,
        [
          'initial0',
          'initial1',
          'initial2',
          'queued0',
          'queued1',
          'queued2',
        ],
      );
    });

    test('should dispose correctly', () async {
      var callCount = 0;

      // Fill rate limit and queue some requests
      for (int i = 0; i < 3; i++) {
        await apiThrottler.call('test$i', () async {
          callCount++;
        });
      }

      unawaited(
        apiThrottler.call('queued', () async {
          callCount++;
        }),
      );

      expect(apiThrottler.queuedRequestsCount, 1);

      apiThrottler.dispose();
      expect(apiThrottler.queuedRequestsCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(callCount, 3); // Only the initial calls, queued one was cancelled
    });
  });
}
