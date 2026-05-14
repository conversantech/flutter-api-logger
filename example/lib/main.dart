import 'package:flutter/material.dart';
import 'package:api_sequence_debugger/api_sequence_debugger.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the debugger (now async for persistence)
  await ApiDebugger.initialize();

  runApp(
    // 3. Wrap your app with ApiDebuggerWrapper
    const ApiDebuggerWrapper(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Api Debugger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 3. Add navigator observer
      navigatorObservers: [ApiDebugger.navigatorObserver()],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _response = 'No requests made yet';
  bool _isLoading = false;

  Future<void> _makeRequest() async {
    setState(() => _isLoading = true);
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
      );
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      setState(() {
        _response = 'Status: ${response.statusCode}\nBody: $responseBody';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makePostRequest() async {
    setState(() => _isLoading = true);
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      );
      request.headers.contentType = ContentType.json;
      request.write(json.encode({'title': 'foo', 'body': 'bar', 'userId': 1}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      setState(() {
        _response = 'Status: ${response.statusCode}\nBody: $responseBody';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Debugger Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tap 6 times anywhere to open Debugger',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _makeRequest,
                child: const Text('Make GET Request'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _makePostRequest,
                child: const Text('Make POST Request'),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Expanded(child: SingleChildScrollView(child: Text(_response))),
            ],
          ),
        ),
      ),
    );
  }
}
