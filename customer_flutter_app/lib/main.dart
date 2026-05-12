import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/user_auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/user_request_screen.dart';
import 'screens/trace_visualizer_screen.dart';
import 'screens/receipt_screen.dart';

void main() {
  runApp(const FikrFreeApp());
}

class FikrFreeApp extends StatelessWidget {
  const FikrFreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FikrFree',
      theme: AppTheme.lightTheme,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/auth': (context) => const UserAuthScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/user_request': (context) => const UserRequestScreen(),
        '/trace_visualizer': (context) => const TraceVisualizerScreen(),
        '/receipt': (context) => const ReceiptScreen(),
      },
    );
  }
}
