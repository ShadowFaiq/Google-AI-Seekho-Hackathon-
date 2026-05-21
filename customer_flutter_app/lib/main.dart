import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/user_auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/user_request_screen.dart';
import 'screens/trace_visualizer_screen.dart';
import 'screens/receipt_screen.dart';
import 'screens/bidding_screen.dart';
import 'provider_screens/provider_login_screen.dart';
import 'provider_screens/provider_dashboard_screen.dart';
import 'screens/chat_screen.dart';

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
        '/bidding': (context) => const BiddingScreen(),
        '/trace_visualizer': (context) => const TraceVisualizerScreen(),
        '/receipt': (context) => const ReceiptScreen(),
        '/provider_login': (context) => const ProviderLoginScreen(),
        '/provider_dashboard': (context) => const ProviderDashboardScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return ChatScreen(
            bookingId: args['booking_id'] ?? 'mock_booking',
            userId: args['user_id'] ?? 'customer_user',
            userName: args['user_name'] ?? 'Customer',
            isProvider: args['is_provider'] ?? false,
          );
        },
      },
    );
  }
}
