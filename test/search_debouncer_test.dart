import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  group('SearchDebouncer', () {
    late SearchDebouncer searchDebouncer;

    setUp(() {
      searchDebouncer = SearchDebouncer(
        delay: const Duration(milliseconds: 100),
        minLength: 2,
      );
    });

    tearDown(() {
      searchDebouncer.dispose();
    });

    test('should execute search callback for valid query', () async {
      String? receivedQuery;

      searchDebouncer.search('flutter', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, 'flutter');
    });

    test('should not execute search callback for short query', () async {
      String? receivedQuery;

      searchDebouncer.search('a', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, isNull);
    });

    test('should trim query when trimQuery is enabled', () async {
      String? receivedQuery;

      searchDebouncer.search('  flutter  ', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, 'flutter');
    });

    test('should not trim query when trimQuery is disabled', () async {
      final nonTrimmingDebouncer = SearchDebouncer(
        delay: const Duration(milliseconds: 100),
        minLength: 2,
        trimQuery: false,
      );

      String? receivedQuery;

      nonTrimmingDebouncer.search('  flutter  ', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, '  flutter  ');

      nonTrimmingDebouncer.dispose();
    });

    test('should call onClearResults for short query', () async {
      var clearCalled = false;

      searchDebouncer.onClearResults = () {
        clearCalled = true;
      };

      searchDebouncer.search('a', (query) {});

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(clearCalled, true);
    });

    test('should execute async search callback', () async {
      String? receivedQuery;

      searchDebouncer.searchAsync('flutter', (query) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(receivedQuery, 'flutter');
    });

    test('should call onClearResultsAsync for short query', () async {
      var clearCalled = false;

      searchDebouncer.onClearResultsAsync = () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        clearCalled = true;
      };

      searchDebouncer.searchAsync('a', (query) async {});

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(clearCalled, true);
    });

    test('should store last query', () async {
      searchDebouncer.search('flutter', (query) {});
      expect(searchDebouncer.lastQuery, 'flutter');

      searchDebouncer.search('  dart  ', (query) {});
      expect(searchDebouncer.lastQuery, 'dart'); // Should be trimmed
    });

    test('should check if query would trigger search', () {
      expect(searchDebouncer.wouldTriggerSearch('a'), false);
      expect(searchDebouncer.wouldTriggerSearch('ab'), true);
      expect(searchDebouncer.wouldTriggerSearch('flutter'), true);
      expect(searchDebouncer.wouldTriggerSearch('  ab  '), true); // Trimmed
      expect(searchDebouncer.wouldTriggerSearch('  a  '), false); // Trimmed
    });

    test('should cancel pending search', () async {
      String? receivedQuery;

      searchDebouncer.search('flutter', (query) {
        receivedQuery = query;
      });

      searchDebouncer.cancel();
      expect(searchDebouncer.isActive, false);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, isNull);
    });

    test('should report active state correctly', () async {
      expect(searchDebouncer.isActive, false);

      searchDebouncer.search('flutter', (query) {});
      expect(searchDebouncer.isActive, true);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(searchDebouncer.isActive, false);
    });

    test('should clear state correctly', () async {
      searchDebouncer.search('flutter', (query) {});
      expect(searchDebouncer.lastQuery, 'flutter');
      expect(searchDebouncer.isActive, true);

      searchDebouncer.clear();
      expect(searchDebouncer.lastQuery, isNull);
      expect(searchDebouncer.isActive, false);
    });

    test('should handle rapid successive searches', () async {
      String? receivedQuery;

      searchDebouncer
        ..search('f', (query) {
          receivedQuery = query;
        })
        ..search('fl', (query) {
          receivedQuery = query;
        })
        ..search('flu', (query) {
          receivedQuery = query;
        })
        ..search('flutter', (query) {
          receivedQuery = query;
        });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, 'flutter');
      expect(searchDebouncer.lastQuery, 'flutter');
    });

    test('should work with different minimum lengths', () async {
      final strictDebouncer = SearchDebouncer(
        delay: const Duration(milliseconds: 50),
        minLength: 5,
      );

      String? receivedQuery;

      strictDebouncer.search('dart', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(receivedQuery, isNull); // Too short

      strictDebouncer.search('flutter', (query) {
        receivedQuery = query;
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(receivedQuery, 'flutter'); // Long enough

      strictDebouncer.dispose();
    });

    test('should only execute latest search when queries overlap', () async {
      String? receivedQuery;
      var callCount = 0;

      searchDebouncer.search('first', (query) {
        receivedQuery = query;
        callCount++;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      searchDebouncer.search('second', (query) {
        receivedQuery = query;
        callCount++;
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, 'second');
      expect(callCount, 1); // Only the latest search should execute
    });

    test('should dispose correctly', () async {
      String? receivedQuery;

      searchDebouncer.search('flutter', (query) {
        receivedQuery = query;
      });

      searchDebouncer.dispose();
      expect(searchDebouncer.isActive, false);
      expect(searchDebouncer.lastQuery, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedQuery, isNull);
    });
  });
}
