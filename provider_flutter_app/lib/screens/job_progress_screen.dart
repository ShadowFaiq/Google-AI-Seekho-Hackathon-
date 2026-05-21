import 'package:flutter/material.dart';
import '../models/job_request_model.dart';

class JobProgressScreen extends StatefulWidget {
  final JobRequestModel job;

  const JobProgressScreen({Key? key, required this.job}) : super(key: key);

  @override
  _JobProgressScreenState createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends State<JobProgressScreen> {
  int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.job.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildStep(1, 'On the way', _currentStep >= 1),
                  _buildStep(2, 'Arrived at location', _currentStep >= 2),
                  _buildStep(3, 'Job in progress', _currentStep >= 3),
                  _buildStep(4, 'Job completed', _currentStep >= 4),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _currentStep < 4
                  ? () {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  : () {
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 4 ? Theme.of(context).primaryColor : const Color(0xFF10B981),
              ),
              child: Text(_currentStep < 4 ? 'Update Status' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, String title, bool isCompleted) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCompleted ? const Color(0xFF10B981) : Colors.grey[300],
        child: Icon(Icons.check, color: isCompleted ? Colors.white : Colors.grey[500]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          color: isCompleted ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
