import 'dart:async';
import 'package:flutter_throttle_debounce/src/types.dart';

/// A utility class for throttling function calls.
///
/// Throttling ensures that a function is called at most once per specified
/// time interval, regardless of how many times it's invoked. This is useful
/// for limiting the frequency of expensive operations like API calls or
/// scroll event handlers.
///
/// Example usage:
/// ```dart
/// final throttler = Throttler(interval: Duration(seconds: 1));
///
/// // In your scroll handler:
/// throttler.call(() {
///   updateScrollPosition();
/// });
/// ```
class Throttler {
  /// Creates a new [Throttler] instance.
  ///
  /// The [interval] parameter specifies the minimum time between function
  /// executions. Defaults to 1 second.
  Throttler({
    this.interval = const Duration(seconds: 1),
  });

  /// The minimum time interval between function executions.
  final Duration interval;

  DateTime? _lastExecution;
  Timer? _timer;

  /// Calls the provided [callback] function, respecting the throttling interval.
  ///
  /// If enough time has passed since the last execution (based on [interval]),
  /// the function is called immediately. Otherwise, it's scheduled to be called
  /// at the end of the current interval.
  ///
  /// Example:
  /// ```dart
  /// throttler.call(() {
  ///   print('This will be called at most once per second');
  /// });
  /// ```
  void call(VoidCallback callback) {
    final now = DateTime.now();

    if (_lastExecution == null || now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      callback();
    } else {
      // Schedule the callback to be executed at the end of the current interval
      _timer?.cancel();
      final remainingTime = interval - now.difference(_lastExecution!);
      _timer = Timer(remainingTime, () {
        _lastExecution = DateTime.now();
        callback();
      });
    }
  }

  /// Calls the provided [callback] function with a [parameter], respecting the throttling interval.
  ///
  /// This is similar to [call] but allows passing a parameter to the callback.
  /// The parameter type is generic and can be any type.
  ///
  /// Example:
  /// ```dart
  /// throttler.callWithParameter<int>(scrollOffset, (offset) {
  ///   updateScrollIndicator(offset);
  /// });
  /// ```
  void callWithParameter<T>(T parameter, ParameterCallback<T> callback) {
    final now = DateTime.now();

    if (_lastExecution == null || now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      callback(parameter);
    } else {
      _timer?.cancel();
      final remainingTime = interval - now.difference(_lastExecution!);
      _timer = Timer(remainingTime, () {
        _lastExecution = DateTime.now();
        callback(parameter);
      });
    }
  }

  /// Calls the provided asynchronous [callback] function, respecting the throttling interval.
  ///
  /// This method is designed for asynchronous operations that need to be throttled.
  /// The callback returns a Future, making it suitable for API calls or other
  /// async operations.
  ///
  /// Example:
  /// ```dart
  /// throttler.callAsync(() async {
  ///   await refreshData();
  /// });
  /// ```
  void callAsync(AsyncVoidCallback callback) {
    final now = DateTime.now();

    if (_lastExecution == null || now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      callback();
    } else {
      _timer?.cancel();
      final remainingTime = interval - now.difference(_lastExecution!);
      _timer = Timer(remainingTime, () {
        _lastExecution = DateTime.now();
        callback();
      });
    }
  }

  /// Calls the provided asynchronous [callback] function with a [parameter], respecting the throttling interval.
  ///
  /// This combines the functionality of [callWithParameter] and [callAsync],
  /// allowing you to pass parameters to asynchronous callbacks.
  ///
  /// Example:
  /// ```dart
  /// throttler.callAsyncWithParameter<String>('userId', (userId) async {
  ///   await fetchUserData(userId);
  /// });
  /// ```
  void callAsyncWithParameter<T>(
      T parameter, AsyncParameterCallback<T> callback) {
    final now = DateTime.now();

    if (_lastExecution == null || now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      callback(parameter);
    } else {
      _timer?.cancel();
      final remainingTime = interval - now.difference(_lastExecution!);
      _timer = Timer(remainingTime, () {
        _lastExecution = DateTime.now();
        callback(parameter);
      });
    }
  }

  /// Cancels any pending throttled function call.
  ///
  /// This immediately cancels the current timer (if any) and prevents
  /// the throttled function from being executed at the end of the interval.
  ///
  /// Example:
  /// ```dart
  /// throttler.cancel(); // Cancels any pending execution
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns true if there is a pending throttled function call.
  ///
  /// This can be useful for checking whether a throttled operation
  /// is currently scheduled to be executed.
  bool get isActive => _timer?.isActive ?? false;

  /// Resets the throttler's internal state.
  ///
  /// This clears the last execution time, allowing the next call
  /// to be executed immediately regardless of the interval.
  ///
  /// Example:
  /// ```dart
  /// throttler.reset(); // Next call will execute immediately
  /// ```
  void reset() {
    cancel();
    _lastExecution = null;
  }

  /// Gets the time remaining until the next execution is allowed.
  ///
  /// Returns [Duration.zero] if a function can be executed immediately,
  /// or the remaining time if we're still within the throttling interval.
  Duration get timeUntilNextExecution {
    if (_lastExecution == null) return Duration.zero;

    final elapsed = DateTime.now().difference(_lastExecution!);
    final remaining = interval - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Disposes of the throttler and cancels any pending operations.
  ///
  /// This should be called when the throttler is no longer needed,
  /// typically in the dispose method of a widget or controller.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   throttler.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    cancel();
  }
}
