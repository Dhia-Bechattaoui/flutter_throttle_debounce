import 'dart:async';
import 'dart:collection';

import 'package:flutter_throttle_debounce/src/types.dart';

/// Allows a [Future] to be ignored without generating warnings.
void unawaited(Future<void> future) {}

/// A specialized throttler for API calls with advanced rate limiting features.
///
/// This class provides sophisticated throttling capabilities specifically designed
/// for API interactions, including request queuing, duplicate request detection,
/// and configurable rate limiting strategies.
///
/// Example usage:
/// ```dart
/// final apiThrottler = ApiThrottler(
///   requestsPerInterval: 10,
///   interval: Duration(minutes: 1),
/// );
///
/// // Throttled API call:
/// apiThrottler.call('getUserData', () async {
///   return await userService.fetchUserData();
/// });
/// ```
class ApiThrottler {
  /// Creates a new [ApiThrottler] instance.
  ///
  /// The [requestsPerInterval] parameter specifies how many requests are
  /// allowed per [interval]. Defaults to 60 requests per minute.
  ///
  /// The [interval] parameter specifies the time window for rate limiting.
  /// Defaults to 1 minute.
  ///
  /// The [enableQueuing] parameter determines whether requests that exceed
  /// the rate limit should be queued for later execution. Defaults to true.
  ///
  /// The [enableDeduplication] parameter determines whether identical
  /// requests (same key) should be deduplicated. Defaults to true.
  ApiThrottler({
    this.requestsPerInterval = 60,
    this.interval = const Duration(minutes: 1),
    this.enableQueuing = true,
    this.enableDeduplication = true,
  });

  /// Maximum number of requests allowed per interval.
  final int requestsPerInterval;

  /// The time interval for rate limiting.
  final Duration interval;

  /// Whether to queue requests that exceed the rate limit.
  final bool enableQueuing;

  /// Whether to deduplicate identical requests.
  final bool enableDeduplication;

  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  final Queue<_QueuedRequest> _requestQueue = Queue<_QueuedRequest>();
  final Map<String, Future<void>> _activeRequests = <String, Future<void>>{};
  Timer? _queueProcessor;

  /// Executes a throttled API call with the given [requestKey].
  ///
  /// The [requestKey] is used for request deduplication when [enableDeduplication]
  /// is true. If a request with the same key is already in progress, this call
  /// will wait for that request to complete instead of making a duplicate call.
  ///
  /// If the rate limit is exceeded and [enableQueuing] is true, the request
  /// will be queued for later execution. Otherwise, it will be executed
  /// immediately regardless of the rate limit.
  ///
  /// Example:
  /// ```dart
  /// await apiThrottler.call('fetchUsers', () async {
  ///   return await apiService.getUsers();
  /// });
  /// ```
  Future<void> call(String requestKey, AsyncVoidCallback callback) async {
    // Check for duplicate requests
    if (enableDeduplication && _activeRequests.containsKey(requestKey)) {
      return _activeRequests[requestKey]!;
    }

    // Check rate limit
    if (_isRateLimited()) {
      if (enableQueuing) {
        return _queueRequest(requestKey, callback);
      }
    }

    return _executeRequest(requestKey, callback);
  }

  /// Executes a throttled API call with a parameter.
  ///
  /// Similar to [call], but allows passing a parameter to the callback.
  /// The [requestKey] is used for deduplication, and the [parameter] is
  /// passed to the callback when executed.
  ///
  /// Example:
  /// ```dart
  /// await apiThrottler.callWithParameter<String>(
  ///   'fetchUser',
  ///   userId,
  ///   (id) async {
  ///     return await apiService.getUser(id);
  ///   },
  /// );
  /// ```
  Future<void> callWithParameter<T>(
    String requestKey,
    T parameter,
    AsyncParameterCallback<T> callback,
  ) async {
    return call(requestKey, () => callback(parameter));
  }

  /// Gets the current number of requests made in the current interval.
  ///
  /// This can be useful for monitoring API usage and displaying
  /// rate limit information to users.
  int get requestsInCurrentInterval {
    _cleanupOldTimestamps();
    return _requestTimestamps.length;
  }

  /// Gets the number of requests remaining in the current interval.
  ///
  /// Returns 0 if the rate limit has been reached.
  int get remainingRequests {
    final current = requestsInCurrentInterval;
    return (requestsPerInterval - current).clamp(0, requestsPerInterval);
  }

  /// Gets the number of requests currently queued for execution.
  ///
  /// This is only relevant when [enableQueuing] is true.
  int get queuedRequestsCount => _requestQueue.length;

  /// Checks if the rate limit is currently exceeded.
  ///
  /// Returns true if no more requests can be made in the current interval.
  bool get isRateLimited {
    return _isRateLimited();
  }

  /// Gets the time until the next request slot becomes available.
  ///
  /// Returns [Duration.zero] if requests can be made immediately.
  Duration get timeUntilNextSlot {
    if (!_isRateLimited()) return Duration.zero;

    _cleanupOldTimestamps();
    if (_requestTimestamps.isEmpty) return Duration.zero;

    final oldestRequest = _requestTimestamps.first;
    final timeUntilExpiry = interval - DateTime.now().difference(oldestRequest);

    return timeUntilExpiry.isNegative ? Duration.zero : timeUntilExpiry;
  }

  /// Cancels all queued requests and clears the request queue.
  ///
  /// This does not affect requests that are currently executing.
  /// Use this when you need to clear pending API calls, for example
  /// when navigating away from a screen.
  ///
  /// Example:
  /// ```dart
  /// apiThrottler.cancelQueuedRequests();
  /// ```
  void cancelQueuedRequests() {
    _requestQueue.clear();
    _queueProcessor?.cancel();
    _queueProcessor = null;
  }

  /// Resets the throttler's internal state.
  ///
  /// This clears all request timestamps and queued requests, effectively
  /// resetting the rate limit. Use with caution as this bypasses the
  /// intended rate limiting behavior.
  void reset() {
    _requestTimestamps.clear();
    cancelQueuedRequests();
  }

  /// Disposes of the API throttler and cancels all pending operations.
  ///
  /// This should be called when the throttler is no longer needed,
  /// typically in the dispose method of a widget or controller.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   apiThrottler.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    cancelQueuedRequests();
  }

  bool _isRateLimited() {
    _cleanupOldTimestamps();
    return _requestTimestamps.length >= requestsPerInterval;
  }

  void _cleanupOldTimestamps() {
    final cutoff = DateTime.now().subtract(interval);
    while (_requestTimestamps.isNotEmpty &&
        _requestTimestamps.first.isBefore(cutoff)) {
      _requestTimestamps.removeFirst();
    }
  }

  Future<void> _executeRequest(
      String requestKey, AsyncVoidCallback callback) async {
    _requestTimestamps.add(DateTime.now());

    final future = callback();
    if (enableDeduplication) {
      _activeRequests[requestKey] = future;
    }

    try {
      await future;
    } finally {
      if (enableDeduplication) {
        _activeRequests.remove(requestKey);
      }
    }
  }

  Future<void> _queueRequest(String requestKey, AsyncVoidCallback callback) {
    final completer = Completer<void>();
    _requestQueue.add(_QueuedRequest(requestKey, callback, completer));
    _startQueueProcessor();
    return completer.future;
  }

  void _startQueueProcessor() {
    if (_queueProcessor?.isActive ?? false) {
      return;
    }

    _queueProcessor = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_requestQueue.isEmpty) {
        _queueProcessor?.cancel();
        _queueProcessor = null;
        return;
      }

      if (!_isRateLimited()) {
        final request = _requestQueue.removeFirst();
        unawaited(
          _executeRequest(request.key, request.callback)
              .then((_) => request.completer.complete())
              .catchError(
                  (Object error) => request.completer.completeError(error)),
        );
      }
    });
  }
}

/// Internal class representing a queued API request.
class _QueuedRequest {
  const _QueuedRequest(this.key, this.callback, this.completer);

  final String key;
  final AsyncVoidCallback callback;
  final Completer<void> completer;
}
