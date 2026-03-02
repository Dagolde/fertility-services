import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fertility Services App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertility Services'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 64,
              color: Colors.pink,
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to Fertility Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'App is working correctly!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Button pressed - App is responsive!'),
            ),
          );
        },
        child: const Icon(Icons.touch_app),
      ),
    );
  }
}
