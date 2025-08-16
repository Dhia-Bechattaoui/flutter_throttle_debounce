import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  group('Package Exports', () {
    test('should export all main classes', () {
      // Test that all main classes are accessible through the main export
      expect(Debouncer, isNotNull);
      expect(Throttler, isNotNull);
      expect(SearchDebouncer, isNotNull);
      expect(ApiThrottler, isNotNull);
    });

    test('should export all type definitions', () {
      // Test that type definitions are accessible
      void voidCallback() {}
      void paramCallback(String param) {}
      Future<void> asyncVoidCallback() async {}
      Future<void> asyncParamCallback(int param) async {}

      // Test the type definitions by using them
      final VoidCallback voidCallbackVar = voidCallback;
      final ParameterCallback<String> paramCallbackVar = paramCallback;
      final AsyncVoidCallback asyncVoidCallbackVar = asyncVoidCallback;
      final AsyncParameterCallback<int> asyncParamCallbackVar =
          asyncParamCallback;

      expect(voidCallbackVar, isNotNull);
      expect(paramCallbackVar, isNotNull);
      expect(asyncVoidCallbackVar, isNotNull);
      expect(asyncParamCallbackVar, isNotNull);
    });

    test('should create instances of all classes', () {
      final debouncer = Debouncer();
      final throttler = Throttler();
      final searchDebouncer = SearchDebouncer();
      final apiThrottler = ApiThrottler();

      expect(debouncer, isA<Debouncer>());
      expect(throttler, isA<Throttler>());
      expect(searchDebouncer, isA<SearchDebouncer>());
      expect(apiThrottler, isA<ApiThrottler>());

      // Clean up
      debouncer.dispose();
      throttler.dispose();
      searchDebouncer.dispose();
      apiThrottler.dispose();
    });

    test('should work together in combination', () async {
      final debouncer = Debouncer(
        delay: const Duration(milliseconds: 50),
      );
      final throttler = Throttler(
        interval: const Duration(milliseconds: 50),
      );

      var debounceCount = 0;
      var throttleCount = 0;

      // Test that they can be used together without conflicts
      debouncer.call(() {
        debounceCount++;
      });

      throttler.call(() {
        throttleCount++;
      });

      expect(throttleCount, 1); // Throttler executes immediately
      expect(debounceCount, 0); // Debouncer waits

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(debounceCount, 1); // Debouncer executed after delay
      expect(throttleCount, 1); // Throttler still at 1

      debouncer.dispose();
      throttler.dispose();
    });
  });
}
