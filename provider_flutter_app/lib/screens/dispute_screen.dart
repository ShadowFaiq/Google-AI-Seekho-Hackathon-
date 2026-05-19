import 'package:flutter/material.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({Key? key}) : super(key: key);

  @override
  _DisputeScreenState createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise a Dispute'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Having an issue with a job or customer?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide details about your dispute. Our support team will review and get back to you within 24 hours.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Dispute Details',
                hintText: 'Describe the issue...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute submitted successfully')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
              child: const Text('Submit Dispute'),
            ),
          ],
        ),
      ),
    );
  }
}
