import 'package:flutter/material.dart';

class UserAuthScreen extends StatelessWidget {
  const UserAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Auth')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/profile_setup'),
          child: const Text('Go to Profile Setup'),
        ),
      ),
    );
  }
}
