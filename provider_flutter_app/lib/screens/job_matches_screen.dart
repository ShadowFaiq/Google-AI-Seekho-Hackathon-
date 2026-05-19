import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'job_progress_screen.dart';

class JobMatchesScreen extends StatelessWidget {
  const JobMatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pendingJobs = MockData.jobRequests.where((j) => j.status == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Matches'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingJobs.length,
        itemBuilder: (context, index) {
          final job = pendingJobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(job.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      Text('Rs ${job.estimatedEarnings}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(job.description, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(job.address, style: const TextStyle(color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Simple mock accept
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Job Accepted!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Accept'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
