import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'provider_login_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = MockData.currentProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
              backgroundImage: NetworkImage(p.profileImageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(p.status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone Number'),
            subtitle: Text(p.phone),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(p.email),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rating'),
            subtitle: Text('${p.rating} / 5.0'),
          ),
        ],
      ),
    );
  }
}
