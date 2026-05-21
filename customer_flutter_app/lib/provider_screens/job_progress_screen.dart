import 'package:flutter/material.dart';
import '../models/job_request_model.dart';
import '../services/provider_api_service.dart';

class JobProgressScreen extends StatefulWidget {
  final JobRequestModel job;

  const JobProgressScreen({Key? key, required this.job}) : super(key: key);

  @override
  _JobProgressScreenState createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends State<JobProgressScreen> {
  int _currentStep = 1;
  bool _isCancelling = false;

  Future<void> _handleCancel() async {
    setState(() {
      _isCancelling = true;
    });
    try {
      await ProviderApiService.cancelJob(widget.job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Job cancelled. Autonomous reallocation triggered.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel job: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Chat with customer',
            onPressed: () {
              Navigator.pushNamed(context, '/chat', arguments: {
                'booking_id': widget.job.id,
                'user_id': ProviderApiService.providerId ?? 'provider_user',
                'user_name': ProviderApiService.providerName ?? 'Provider',
                'is_provider': true,
              });
            },
          ),
        ],
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentStep < 4 ? 'Update Status' : 'Finish'),
                  ),
                ),
                if (_currentStep < 4) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isCancelling ? null : _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          )
                        : const Text('Cancel Job', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ],
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
