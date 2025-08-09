import 'dart:async';
import 'package:flutter_throttle_debounce/src/types.dart';

/// A utility class for debouncing function calls.
///
/// Debouncing ensures that a function is only called after a specified delay
/// has passed since the last time it was invoked. This is particularly useful
/// for handling user input events like typing in search boxes or button clicks.
///
/// Example usage:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 500));
///
/// // In your widget's onChanged callback:
/// debouncer.call(() {
///   performSearch(query);
/// });
/// ```
class Debouncer {
  /// Creates a new [Debouncer] instance.
  ///
  /// The [delay] parameter specifies how long to wait after the last call
  /// before executing the function. Defaults to 300 milliseconds.
  Debouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  /// The delay duration before executing the debounced function.
  final Duration delay;

  Timer? _timer;

  /// Calls the provided [callback] function after the specified [delay].
  ///
  /// If this method is called again before the delay expires, the previous
  /// timer is cancelled and a new one is started. This ensures that the
  /// callback is only executed after the specified delay has passed since
  /// the last invocation.
  ///
  /// Example:
  /// ```dart
  /// debouncer.call(() {
  ///   print('This will only print after 300ms of inactivity');
  /// });
  /// ```
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Calls the provided [callback] function with a [parameter] after the specified [delay].
  ///
  /// This is similar to [call] but allows passing a parameter to the callback.
  /// The parameter type is generic and can be any type.
  ///
  /// Example:
  /// ```dart
  /// debouncer.callWithParameter<String>('search query', (query) {
  ///   performSearch(query);
  /// });
  /// ```
  void callWithParameter<T>(T parameter, ParameterCallback<T> callback) {
    _timer?.cancel();
    _timer = Timer(delay, () => callback(parameter));
  }

  /// Calls the provided asynchronous [callback] function after the specified [delay].
  ///
  /// This method is designed for asynchronous operations that need to be debounced.
  /// The callback returns a Future, making it suitable for API calls or other
  /// async operations.
  ///
  /// Example:
  /// ```dart
  /// debouncer.callAsync(() async {
  ///   await fetchDataFromApi();
  /// });
  /// ```
  void callAsync(AsyncVoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Calls the provided asynchronous [callback] function with a [parameter] after the specified [delay].
  ///
  /// This combines the functionality of [callWithParameter] and [callAsync],
  /// allowing you to pass parameters to asynchronous callbacks.
  ///
  /// Example:
  /// ```dart
  /// debouncer.callAsyncWithParameter<String>('query', (query) async {
  ///   await searchApi(query);
  /// });
  /// ```
  void callAsyncWithParameter<T>(
      T parameter, AsyncParameterCallback<T> callback) {
    _timer?.cancel();
    _timer = Timer(delay, () async => callback(parameter));
  }

  /// Cancels any pending debounced function call.
  ///
  /// This immediately cancels the current timer (if any) and prevents
  /// the debounced function from being executed.
  ///
  /// Example:
  /// ```dart
  /// debouncer.cancel(); // Cancels any pending execution
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns true if there is a pending debounced function call.
  ///
  /// This can be useful for checking whether a debounced operation
  /// is currently waiting to be executed.
  bool get isActive => _timer?.isActive ?? false;

  /// Disposes of the debouncer and cancels any pending operations.
  ///
  /// This should be called when the debouncer is no longer needed,
  /// typically in the dispose method of a widget or controller.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   debouncer.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    cancel();
  }
}
