import 'package:flutter/material.dart';

class TraceVisualizerScreen extends StatelessWidget {
  const TraceVisualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trace Visualizer')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/receipt'),
          child: const Text('Go to Receipt'),
        ),
      ),
    );
  }
}
