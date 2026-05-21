import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/mock_data.dart';
import 'provider_login_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = ApiService.providerName ?? MockData.currentProvider.name;
    final email = ApiService.providerEmail ?? MockData.currentProvider.email;
    final phone = MockData.currentProvider.phone;
    final rating = MockData.currentProvider.rating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ApiService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProviderLoginScreen()),
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(
              ApiService.jwtToken != null ? 'Connected to Backend' : 'Mock Mode',
              style: TextStyle(
                color: ApiService.jwtToken != null ? const Color(0xFF10B981) : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (ApiService.providerId != null)
            Center(
              child: Text(
                'ID: ${ApiService.providerId}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone Number'),
            subtitle: Text(phone),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rating'),
            subtitle: Text('$rating / 5.0'),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Auth Token'),
            subtitle: Text(
              ApiService.jwtToken != null
                  ? '${ApiService.jwtToken!.substring(0, 20)}...'
                  : 'Not authenticated',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
