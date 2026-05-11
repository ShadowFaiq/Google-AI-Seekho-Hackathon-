import 'package:flutter/material.dart';

class UserRequestScreen extends StatelessWidget {
  const UserRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Request Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/trace_visualizer'),
          child: const Text('Go to Trace Visualizer'),
        ),
      ),
    );
  }
}
