import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/provider_login_screen.dart';

void main() {
  runApp(const FikarFreeProviderApp());
}

class FikarFreeProviderApp extends StatelessWidget {
  const FikarFreeProviderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fikar Free Provider',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ProviderLoginScreen(),
    );
  }
}
