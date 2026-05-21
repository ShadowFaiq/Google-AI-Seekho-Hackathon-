import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class EarningsReputationScreen extends StatelessWidget {
  const EarningsReputationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = MockData.currentProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Reputation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Total Earnings', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Rs ${p.totalEarnings}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Provider Rating', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 32),
                      const SizedBox(width: 8),
                      Text('${p.rating}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Based on ${p.totalJobs} completed jobs', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTransactionTile('AC Repair', '1500.0', '12 May 2026'),
          _buildTransactionTile('Plumbing Fix', '800.0', '10 May 2026'),
          _buildTransactionTile('Electrical Wiring', '1200.0', '08 May 2026'),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(String title, String amount, String date) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE2E8F0),
        child: Icon(Icons.check, color: Color(0xFF10B981)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text('+ Rs $amount', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
