/// Type definitions for the flutter_throttle_debounce package.
library;

/// A callback function type that takes no parameters and returns void.
///
/// This is the most common callback type used throughout the package
/// for simple debounced and throttled operations.
typedef VoidCallback = void Function();

/// A callback function type that takes a parameter of type [T] and returns void.
///
/// This is used for operations that need to pass data to the callback,
/// such as search queries or API responses.
typedef ParameterCallback<T> = void Function(T parameter);

/// A callback function type that takes a parameter of type [T] and returns a Future.
///
/// This is used for asynchronous operations that need to be debounced or throttled,
/// such as API calls or database operations.
typedef AsyncParameterCallback<T> = Future<void> Function(T parameter);

/// A callback function type that returns a Future and takes no parameters.
///
/// This is used for asynchronous operations that don't require parameters,
/// such as refreshing data or performing cleanup operations.
typedef AsyncVoidCallback = Future<void> Function();
