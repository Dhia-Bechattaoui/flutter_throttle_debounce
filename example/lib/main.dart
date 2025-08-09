import 'package:flutter/material.dart';
import 'package:flutter_throttle_debounce/flutter_throttle_debounce.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Throttle Debounce Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final _throttler = Throttler(interval: const Duration(seconds: 1));
  final _searchDebouncer = SearchDebouncer(
    delay: const Duration(milliseconds: 300),
    minLength: 2,
  );
  final _apiThrottler = ApiThrottler(
    requestsPerInterval: 5,
    interval: const Duration(seconds: 10),
  );

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _searchResults = [];
  List<String> _scrollEvents = [];
  List<String> _apiCalls = [];
  int _debounceCounter = 0;
  int _throttleCounter = 0;

  @override
  void initState() {
    super.initState();

    _searchDebouncer.onClearResults = () {
      setState(() {
        _searchResults.clear();
      });
    };

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _throttler.dispose();
    _searchDebouncer.dispose();
    _apiThrottler.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _throttler.callWithParameter(_scrollController.offset, (offset) {
      setState(() {
        _scrollEvents.add('Scroll: ${offset.toStringAsFixed(1)}');
        if (_scrollEvents.length > 10) {
          _scrollEvents.removeAt(0);
        }
      });
    });
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.search(query, (searchQuery) {
      setState(() {
        _searchResults = _generateSearchResults(searchQuery);
      });
    });
  }

  List<String> _generateSearchResults(String query) {
    // Simulate search results
    return List.generate(
      5,
      (index) => '$query - Result ${index + 1}',
    );
  }

  void _onDebounceButtonPressed() {
    _debouncer.call(() {
      setState(() {
        _debounceCounter++;
      });
    });
  }

  void _onThrottleButtonPressed() {
    _throttler.call(() {
      setState(() {
        _throttleCounter++;
      });
    });
  }

  void _makeApiCall() {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _apiThrottler.call('demo-api-call', () async {
      // Simulate API call delay
      await Future<void>.delayed(const Duration(milliseconds: 100));

      setState(() {
        _apiCalls.add('API Call at $timestamp');
        if (_apiCalls.length > 10) {
          _apiCalls.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Throttle Debounce Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSearchSection(),
          const SizedBox(height: 24),
          _buildDebounceSection(),
          const SizedBox(height: 24),
          _buildThrottleSection(),
          const SizedBox(height: 24),
          _buildApiThrottleSection(),
          const SizedBox(height: 24),
          _buildScrollSection(),
          // Add some extra space to enable scrolling
          const SizedBox(height: 1000),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Debouncer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Type in the search field. Results appear after 300ms delay and minimum 2 characters.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_searchResults.isNotEmpty) ...[
              const Text('Search Results:'),
              const SizedBox(height: 4),
              ...(_searchResults.map((result) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $result'),
                  ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebounceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debouncer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Click rapidly. Counter updates only after 500ms of inactivity.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _onDebounceButtonPressed,
                  child: const Text('Debounced Button'),
                ),
                const SizedBox(width: 16),
                Text('Counter: $_debounceCounter'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThrottleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Throttler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Click rapidly. Counter updates at most once per second.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _onThrottleButtonPressed,
                  child: const Text('Throttled Button'),
                ),
                const SizedBox(width: 16),
                Text('Counter: $_throttleCounter'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiThrottleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Throttler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Click rapidly. Maximum 5 API calls per 10 seconds. Remaining: ${_apiThrottler.remainingRequests}',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _makeApiCall,
              child: const Text('Make API Call'),
            ),
            const SizedBox(height: 12),
            if (_apiCalls.isNotEmpty) ...[
              const Text('Recent API Calls:'),
              const SizedBox(height: 4),
              ...(_apiCalls.map((call) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $call'),
                  ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScrollSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scroll Throttler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scroll this page. Events are throttled to once per second.',
            ),
            const SizedBox(height: 12),
            if (_scrollEvents.isNotEmpty) ...[
              const Text('Recent Scroll Events:'),
              const SizedBox(height: 4),
              ...(_scrollEvents.map((event) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $event'),
                  ))),
            ],
          ],
        ),
      ),
    );
  }
}
