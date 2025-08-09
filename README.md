# Flutter Throttle Debounce

[![pub package](https://img.shields.io/pub/v/flutter_throttle_debounce.svg)](https://pub.dev/packages/flutter_throttle_debounce)
[![pub points](https://img.shields.io/pub/points/flutter_throttle_debounce?logo=dart)](https://pub.dev/packages/flutter_throttle_debounce/score)
[![popularity](https://img.shields.io/pub/popularity/flutter_throttle_debounce?logo=dart)](https://pub.dev/packages/flutter_throttle_debounce/score)
[![likes](https://img.shields.io/pub/likes/flutter_throttle_debounce?logo=dart)](https://pub.dev/packages/flutter_throttle_debounce/score)

A comprehensive debouncing and throttling utility for search, API calls, and user interactions in Flutter applications. Optimize performance by controlling the frequency of function executions with easy-to-use, memory-efficient utilities.

## Features

✨ **Comprehensive Utilities**
- 🚀 **Debouncer**: Delays function execution until after a specified time has passed since the last invocation
- ⚡ **Throttler**: Ensures function is called at most once per specified time interval
- 🔍 **SearchDebouncer**: Specialized debouncer for search inputs with configurable minimum query length
- 🌐 **ApiThrottler**: Advanced rate limiting for API calls with request queuing and deduplication

🎯 **Key Benefits**
- 📱 **Cross-Platform**: Works on all Flutter platforms (Android, iOS, Web, Desktop)
- 🧠 **Memory Efficient**: Automatic cleanup and cancellation of pending operations
- 🔒 **Type Safe**: Full Dart type safety with generic support
- 📦 **Zero Dependencies**: No external dependencies beyond Flutter SDK
- ⚡ **High Performance**: Optimized for high-frequency operations
- 🛠️ **Easy Integration**: Simple API with comprehensive documentation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_throttle_debounce: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Debouncing

Perfect for search fields, form validation, or any user input where you want to wait for the user to finish typing:

```dart
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

final debouncer = Debouncer(delay: Duration(milliseconds: 500));

// In your widget's onChanged callback:
debouncer.call(() {
  performSearch(query);
});
```

### Basic Throttling

Ideal for scroll handlers, button clicks, or any high-frequency events:

```dart
final throttler = Throttler(interval: Duration(seconds: 1));

// In your scroll handler:
throttler.call(() {
  updateScrollPosition();
});
```

### Search-Specific Debouncing

Specialized for search functionality with minimum query length validation:

```dart
final searchDebouncer = SearchDebouncer(
  delay: Duration(milliseconds: 300),
  minLength: 2,
);

searchDebouncer.search(query, (trimmedQuery) {
  performSearch(trimmedQuery);
});
```

### API Rate Limiting

Advanced throttling for API calls with queuing and deduplication:

```dart
final apiThrottler = ApiThrottler(
  requestsPerInterval: 10,
  interval: Duration(minutes: 1),
);

await apiThrottler.call('getUserData', () async {
  return await userService.fetchUserData();
});
```

## Comprehensive Usage Examples

### 1. Search Field with Debouncing

```dart
class SearchWidget extends StatefulWidget {
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _searchDebouncer = SearchDebouncer(
    delay: Duration(milliseconds: 300),
    minLength: 2,
  );
  final _searchController = TextEditingController();
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    _searchDebouncer.onClearResults = () {
      setState(() {
        _searchResults.clear();
      });
    };
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.search(query, (searchQuery) async {
      final results = await performSearch(searchQuery);
      setState(() {
        _searchResults = results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_searchResults[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### 2. Scroll Event Throttling

```dart
class ScrollableList extends StatefulWidget {
  @override
  _ScrollableListState createState() => _ScrollableListState();
}

class _ScrollableListState extends State<ScrollableList> {
  final _scrollController = ScrollController();
  final _scrollThrottler = Throttler(interval: Duration(milliseconds: 100));
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollThrottler.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollThrottler.callWithParameter(_scrollController.offset, (offset) {
      setState(() {
        _showScrollToTop = offset > 200;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        controller: _scrollController,
        itemCount: 1000,
        itemBuilder: (context, index) {
          return ListTile(title: Text('Item $index'));
        },
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
```

### 3. API Call Management

```dart
class UserService {
  final _apiThrottler = ApiThrottler(
    requestsPerInterval: 60,
    interval: Duration(minutes: 1),
    enableQueuing: true,
    enableDeduplication: true,
  );

  Future<User> fetchUser(String userId) async {
    return await _apiThrottler.call('fetchUser-$userId', () async {
      final response = await http.get(
        Uri.parse('https://api.example.com/users/$userId'),
      );
      return User.fromJson(json.decode(response.body));
    });
  }

  Future<List<User>> searchUsers(String query) async {
    return await _apiThrottler.callWithParameter(
      'searchUsers',
      query,
      (searchQuery) async {
        final response = await http.get(
          Uri.parse('https://api.example.com/users/search?q=$searchQuery'),
        );
        return (json.decode(response.body) as List)
            .map((json) => User.fromJson(json))
            .toList();
      },
    );
  }

  void dispose() {
    _apiThrottler.dispose();
  }
}
```

### 4. Form Validation with Debouncing

```dart
class ValidatedForm extends StatefulWidget {
  @override
  _ValidatedFormState createState() => _ValidatedFormState();
}

class _ValidatedFormState extends State<ValidatedForm> {
  final _emailDebouncer = Debouncer(delay: Duration(milliseconds: 500));
  final _usernameDebouncer = Debouncer(delay: Duration(milliseconds: 500));
  
  String? _emailError;
  String? _usernameError;

  @override
  void dispose() {
    _emailDebouncer.dispose();
    _usernameDebouncer.dispose();
    super.dispose();
  }

  void _validateEmail(String email) {
    _emailDebouncer.call(() async {
      final isValid = await validateEmailWithServer(email);
      setState(() {
        _emailError = isValid ? null : 'Email is already taken';
      });
    });
  }

  void _validateUsername(String username) {
    _usernameDebouncer.call(() async {
      final isValid = await validateUsernameWithServer(username);
      setState(() {
        _usernameError = isValid ? null : 'Username is already taken';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            onChanged: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _emailError,
            ),
          ),
          TextFormField(
            onChanged: _validateUsername,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _usernameError,
            ),
          ),
        ],
      ),
    );
  }
}
```

## API Reference

### Debouncer

Delays function execution until after a specified time has passed since the last invocation.

#### Constructor
```dart
Debouncer({
  Duration delay = const Duration(milliseconds: 300),
})
```

#### Methods
- `call(VoidCallback callback)` - Execute callback after delay
- `callWithParameter<T>(T parameter, ParameterCallback<T> callback)` - Execute callback with parameter
- `callAsync(AsyncVoidCallback callback)` - Execute async callback
- `callAsyncWithParameter<T>(T parameter, AsyncParameterCallback<T> callback)` - Execute async callback with parameter
- `cancel()` - Cancel pending execution
- `dispose()` - Clean up resources

#### Properties
- `bool isActive` - Whether there's a pending execution

### Throttler

Ensures function is called at most once per specified time interval.

#### Constructor
```dart
Throttler({
  Duration interval = const Duration(seconds: 1),
})
```

#### Methods
- `call(VoidCallback callback)` - Execute callback respecting throttle interval
- `callWithParameter<T>(T parameter, ParameterCallback<T> callback)` - Execute callback with parameter
- `callAsync(AsyncVoidCallback callback)` - Execute async callback
- `callAsyncWithParameter<T>(T parameter, AsyncParameterCallback<T> callback)` - Execute async callback with parameter
- `cancel()` - Cancel pending execution
- `reset()` - Reset throttle state
- `dispose()` - Clean up resources

#### Properties
- `bool isActive` - Whether there's a pending execution
- `Duration timeUntilNextExecution` - Time until next execution is allowed

### SearchDebouncer

Specialized debouncer for search functionality with minimum query length validation.

#### Constructor
```dart
SearchDebouncer({
  Duration delay = const Duration(milliseconds: 300),
  int minLength = 1,
  bool trimQuery = true,
})
```

#### Methods
- `search(String query, ParameterCallback<String> onSearch)` - Perform debounced search
- `searchAsync(String query, AsyncParameterCallback<String> onSearch)` - Perform async debounced search
- `wouldTriggerSearch(String query)` - Check if query would trigger search
- `cancel()` - Cancel pending search
- `clear()` - Clear state and cancel
- `dispose()` - Clean up resources

#### Properties
- `String? lastQuery` - Last processed query
- `bool isActive` - Whether there's a pending search
- `VoidCallback? onClearResults` - Callback for clearing results
- `AsyncVoidCallback? onClearResultsAsync` - Async callback for clearing results

### ApiThrottler

Advanced rate limiting for API calls with request queuing and deduplication.

#### Constructor
```dart
ApiThrottler({
  int requestsPerInterval = 60,
  Duration interval = const Duration(minutes: 1),
  bool enableQueuing = true,
  bool enableDeduplication = true,
})
```

#### Methods
- `call(String requestKey, AsyncVoidCallback callback)` - Execute throttled API call
- `callWithParameter<T>(String requestKey, T parameter, AsyncParameterCallback<T> callback)` - Execute with parameter
- `cancelQueuedRequests()` - Cancel all queued requests
- `reset()` - Reset throttler state
- `dispose()` - Clean up resources

#### Properties
- `int requestsInCurrentInterval` - Current request count
- `int remainingRequests` - Remaining requests in interval
- `int queuedRequestsCount` - Number of queued requests
- `bool isRateLimited` - Whether rate limit is exceeded
- `Duration timeUntilNextSlot` - Time until next request slot

## Performance Considerations

### Memory Usage
- All utilities automatically clean up timers and references
- Always call `dispose()` when no longer needed
- Use the utilities as instance variables, not local variables

### Best Practices
- Choose appropriate delay/interval values for your use case
- For search: 300-500ms delay is usually optimal
- For scroll events: 100-200ms interval works well
- For API calls: Match your API rate limits

### Flutter Integration
- Dispose utilities in `StatefulWidget.dispose()`
- Use with controllers and services for better organization
- Consider using with state management solutions

## Migration Guide

### From other debounce/throttle packages

This package provides a more comprehensive and type-safe API. Here's how to migrate:

```dart
// Old package
Timer? _debounceTimer;
void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    performSearch(query);
  });
}

// This package
final _searchDebouncer = SearchDebouncer(delay: Duration(milliseconds: 500));
void _onSearchChanged(String query) {
  _searchDebouncer.search(query, (searchQuery) {
    performSearch(searchQuery);
  });
}
```

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and [code of conduct](CODE_OF_CONDUCT.md).

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for details about changes in each version.

## Support

- 📄 [Documentation](https://pub.dev/documentation/flutter_throttle_debounce/latest/)
- 🐛 [Issue Tracker](https://github.com/Dhia-Bechattaoui/flutter_throttle_debounce/issues)
- 💬 [Discussions](https://github.com/Dhia-Bechattaoui/flutter_throttle_debounce/discussions)

---

Made with ❤️ for the Flutter community
