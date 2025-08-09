# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2024-01-01

### Added
- Initial release of flutter_throttle_debounce package
- `Debouncer` class for debouncing function calls with customizable delay
- `Throttler` class for throttling function calls with customizable interval
- `SearchDebouncer` specialized class for search input debouncing
- `ApiThrottler` specialized class for API call throttling
- Comprehensive documentation and examples
- Support for all Flutter platforms (Android, iOS, Web, Desktop)
- Complete test coverage
- Performance optimizations for high-frequency operations

### Features
- **Debouncing**: Delays function execution until after a specified time has passed since the last invocation
- **Throttling**: Ensures function is called at most once per specified time interval
- **Search Optimization**: Specialized debouncer for search inputs with configurable minimum query length
- **API Rate Limiting**: Built-in throttling for API calls to prevent rate limit violations
- **Memory Efficient**: Automatic cleanup and cancellation of pending operations
- **Type Safe**: Full Dart type safety with generic support
- **Platform Agnostic**: Works across all Flutter supported platforms
- **Zero Dependencies**: No external dependencies beyond Flutter SDK
