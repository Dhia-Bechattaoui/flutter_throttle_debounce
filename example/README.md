# Flutter Throttle Debounce Example

This example demonstrates the comprehensive usage of the `flutter_throttle_debounce` package.

## Features Demonstrated

### 1. Search Debouncer
- Real-time search with debounced input
- Minimum query length validation
- Automatic result clearing for short queries

### 2. Basic Debouncer
- Button click debouncing
- Prevents rapid successive executions

### 3. Basic Throttler
- Button click throttling
- Limits execution frequency

### 4. API Throttler
- Advanced rate limiting for API calls
- Request queuing and deduplication
- Rate limit monitoring

### 5. Scroll Throttler
- Scroll event throttling
- Performance optimization for scroll handlers

## Running the Example

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the example:
   ```bash
   flutter run
   ```

## How to Use

### Search Field
Type in the search field to see debounced search results. The search will only trigger after you stop typing for 300ms and have entered at least 2 characters.

### Debounced Button
Click the "Debounced Button" rapidly. Notice that the counter only increases after you stop clicking for 500ms.

### Throttled Button
Click the "Throttled Button" rapidly. Notice that the counter increases at most once per second, regardless of how fast you click.

### API Calls
Click the "Make API Call" button rapidly. The throttler allows maximum 5 calls per 10 seconds. Additional calls are queued.

### Scrolling
Scroll the page to see throttled scroll events. Events are captured at most once per second for performance.

## Code Structure

- `main.dart` - Main example application
- Shows practical usage patterns
- Demonstrates proper disposal in widget lifecycle
- Includes performance optimizations
