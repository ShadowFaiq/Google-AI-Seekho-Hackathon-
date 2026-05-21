import 'package:flutter/material.dart';
import '../services/provider_api_service.dart';
import '../data/mock_data.dart';
import '../models/job_request_model.dart';
import 'job_matches_screen.dart';
import 'job_progress_screen.dart';
import 'provider_profile_screen.dart';
import 'earnings_reputation_screen.dart';

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

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Map<String, dynamic>? _dashboardData;
  bool _isOnline = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ProviderApiService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to mock data silently
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _toggleAvailability() async {
    final newStatus = !_isOnline;
    try {
      await ProviderApiService.setAvailability(newStatus);
      setState(() { _isOnline = newStatus; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus ? '✅ You are now Online' : '🔴 You are now Offline')),
        );
      }
    } catch (_) {
      setState(() { _isOnline = newStatus; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerName = ProviderApiService.providerName ?? MockData.currentProvider.name;
    final earnings = _dashboardData?['earnings_today_pkr'] ?? MockData.currentProvider.totalEarnings;
    final todayJobs = _dashboardData?['today_jobs'] ?? MockData.currentProvider.totalJobs;
    final nextSlot = _dashboardData?['next_available_slot'] ?? '04:00 PM';
    final activeJob = MockData.jobRequests.firstWhere((j) => j.status == 'in_progress', orElse: () => MockData.jobRequests.first);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $providerName', 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Ready for work today?', 
                      style: TextStyle(color: Colors.grey)),
                  ],
                ),
                // Online/Offline toggle
                GestureDetector(
                  onTap: _toggleAvailability,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOnline ? Icons.circle : Icons.circle_outlined,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Earnings', 'Rs $earnings', Icons.account_balance_wallet, context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Jobs', '$todayJobs', Icons.check_circle_outline, context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Next Slot', nextSlot, Icons.schedule, context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsReputationScreen()));
                    },
                    child: _buildStatCard('Earnings', 'View All →', Icons.trending_up, context),
                  ),
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
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
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
