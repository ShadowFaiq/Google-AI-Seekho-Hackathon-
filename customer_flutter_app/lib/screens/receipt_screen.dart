import 'package:flutter/material.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/welcome')),
          child: const Text('Back to Welcome'),
        ),
      ),
    );
  }
}
