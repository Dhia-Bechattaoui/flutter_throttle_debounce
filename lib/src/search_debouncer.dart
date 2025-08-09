import 'dart:async';
import 'package:flutter_throttle_debounce/src/types.dart';

/// A specialized debouncer for search functionality.
///
/// This class extends the basic debouncing concept with search-specific features
/// like minimum query length validation and query trimming. It's optimized for
/// handling user input in search fields where you want to avoid unnecessary
/// API calls for empty or very short queries.
///
/// Example usage:
/// ```dart
/// final searchDebouncer = SearchDebouncer(
///   delay: Duration(milliseconds: 300),
///   minLength: 2,
/// );
///
/// // In your search field's onChanged callback:
/// searchDebouncer.search(query, (trimmedQuery) {
///   performSearch(trimmedQuery);
/// });
/// ```
class SearchDebouncer {
  /// Creates a new [SearchDebouncer] instance.
  ///
  /// The [delay] parameter specifies how long to wait after the last input
  /// before executing the search. Defaults to 300 milliseconds.
  ///
  /// The [minLength] parameter specifies the minimum length a query must have
  /// (after trimming) before the search is executed. Defaults to 1.
  ///
  /// The [trimQuery] parameter determines whether to automatically trim
  /// whitespace from queries. Defaults to true.
  SearchDebouncer({
    this.delay = const Duration(milliseconds: 300),
    this.minLength = 1,
    this.trimQuery = true,
  });

  /// The delay duration before executing the search.
  final Duration delay;

  /// The minimum length a query must have before search is executed.
  final int minLength;

  /// Whether to automatically trim whitespace from queries.
  final bool trimQuery;

  Timer? _timer;
  String? _lastQuery;

  /// Performs a debounced search with the given [query].
  ///
  /// The [query] is processed according to the [trimQuery] setting, then
  /// checked against [minLength]. If the processed query meets the requirements,
  /// the [onSearch] callback is called after the [delay] period.
  ///
  /// If called multiple times before the delay expires, only the last query
  /// will be processed.
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.search('flutter', (query) {
  ///   print('Searching for: $query');
  /// });
  /// ```
  void search(String query, ParameterCallback<String> onSearch) {
    _timer?.cancel();

    final processedQuery = trimQuery ? query.trim() : query;
    _lastQuery = processedQuery;

    if (processedQuery.length >= minLength) {
      _timer = Timer(delay, () {
        // Only execute if this is still the latest query
        if (_lastQuery == processedQuery) {
          onSearch(processedQuery);
        }
      });
    } else {
      // If query is too short, we might want to clear results
      _timer = Timer(delay, () {
        if (_lastQuery == processedQuery) {
          onClearResults?.call();
        }
      });
    }
  }

  /// Performs a debounced asynchronous search with the given [query].
  ///
  /// Similar to [search], but designed for asynchronous search operations
  /// that return a Future, such as API calls.
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.searchAsync('flutter', (query) async {
  ///   final results = await searchApi(query);
  ///   updateResults(results);
  /// });
  /// ```
  void searchAsync(String query, AsyncParameterCallback<String> onSearch) {
    _timer?.cancel();

    final processedQuery = trimQuery ? query.trim() : query;
    _lastQuery = processedQuery;

    if (processedQuery.length >= minLength) {
      _timer = Timer(delay, () async {
        // Only execute if this is still the latest query
        if (_lastQuery == processedQuery) {
          await onSearch(processedQuery);
        }
      });
    } else {
      _timer = Timer(delay, () async {
        if (_lastQuery == processedQuery) {
          await onClearResultsAsync?.call();
        }
      });
    }
  }

  /// Optional callback that's called when the query becomes too short.
  ///
  /// This is useful for clearing search results when the user deletes
  /// characters and the query falls below [minLength].
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.onClearResults = () {
  ///   setState(() {
  ///     searchResults.clear();
  ///   });
  /// };
  /// ```
  VoidCallback? onClearResults;

  /// Optional asynchronous callback that's called when the query becomes too short.
  ///
  /// Similar to [onClearResults] but for asynchronous operations.
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.onClearResultsAsync = () async {
  ///   await clearSearchCache();
  /// };
  /// ```
  AsyncVoidCallback? onClearResultsAsync;

  /// Gets the last processed query.
  ///
  /// Returns the last query that was processed by the debouncer,
  /// after trimming (if enabled) but regardless of whether it
  /// met the minimum length requirement.
  String? get lastQuery => _lastQuery;

  /// Checks if the given [query] would trigger a search.
  ///
  /// Returns true if the processed query (after trimming if enabled)
  /// meets the minimum length requirement.
  ///
  /// This can be useful for UI logic, such as showing/hiding
  /// search indicators or enabling/disabling search buttons.
  bool wouldTriggerSearch(String query) {
    final processedQuery = trimQuery ? query.trim() : query;
    return processedQuery.length >= minLength;
  }

  /// Cancels any pending search operation.
  ///
  /// This immediately cancels the current timer (if any) and prevents
  /// the search callback from being executed.
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.cancel(); // Cancels any pending search
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns true if there is a pending search operation.
  ///
  /// This can be useful for showing loading indicators or
  /// determining whether a search is about to be executed.
  bool get isActive => _timer?.isActive ?? false;

  /// Clears the last query and cancels any pending operations.
  ///
  /// This resets the debouncer to its initial state, clearing
  /// the stored last query and cancelling any pending timers.
  ///
  /// Example:
  /// ```dart
  /// searchDebouncer.clear(); // Reset to initial state
  /// ```
  void clear() {
    cancel();
    _lastQuery = null;
  }

  /// Disposes of the search debouncer and cancels any pending operations.
  ///
  /// This should be called when the search debouncer is no longer needed,
  /// typically in the dispose method of a widget or controller.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   searchDebouncer.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    clear();
  }
}
