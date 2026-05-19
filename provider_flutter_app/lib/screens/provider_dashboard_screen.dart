import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/job_request_model.dart';
import 'job_matches_screen.dart';
import 'job_progress_screen.dart';
import 'provider_profile_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({Key? key}) : super(key: key);

  @override
  _ProviderDashboardScreenState createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardContent(),
    const JobMatchesScreen(),
    const ProviderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeJob = MockData.jobRequests.firstWhere((j) => j.status == 'in_progress', orElse: () => MockData.jobRequests.first);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${MockData.currentProvider.name}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Ready for work today?', 
                    style: TextStyle(color: Colors.grey)),
                ],
              ),
              CircleAvatar(
                backgroundImage: NetworkImage(MockData.currentProvider.profileImageUrl),
                radius: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Earnings', 'Rs ${MockData.currentProvider.totalEarnings}', Icons.account_balance_wallet, context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Jobs Done', '${MockData.currentProvider.totalJobs}', Icons.check_circle_outline, context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Current Active Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(activeJob.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(activeJob.address),
                  const SizedBox(height: 8),
                  Text('Estimated: Rs ${activeJob.estimatedEarnings}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => JobProgressScreen(job: activeJob)));
                },
                child: const Text('View'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
