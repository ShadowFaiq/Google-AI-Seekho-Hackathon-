import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_chip.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepNavy,
              AppColors.mutedTeal,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Glows
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mutedTeal.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.inkBlue.withValues(alpha: 0.25),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.softIvory,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/fikrfree_logo.png',
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Fikr',
                                  style: TextStyle(
                                    color: AppColors.cardWhite,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Free',
                                  style: TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                  // Main Heading
                  Text(
                    'Help is closer than you think.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cardWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Describe your problem and let AI prepare your request for trusted nearby helpers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Live Request Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.softIvory,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LIVE REQUEST PREVIEW',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const StatusChip(
                              label: 'AI MATCHED',
                              icon: Icons.auto_awesome,
                              backgroundColor: AppColors.mutedTeal,
                              textColor: AppColors.cardWhite,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'AC repair needed near Gulberg III',
                          style: TextStyle(
                            color: AppColors.mainText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Stats Rows
                        _buildStatRow(
                          icon: Icons.people,
                          title: 'NEARBY HELPERS',
                          value: '12 found',
                        ),
                        const Divider(color: AppColors.divider),
                        _buildStatRow(
                          icon: Icons.access_time,
                          title: 'RESPONSE TIME',
                          value: '8 min avg',
                        ),
                        const Divider(color: AppColors.divider),
                        _buildStatRow(
                          icon: Icons.verified_user,
                          title: 'TRUST CHECK',
                          value: 'Verified profiles',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Benefit Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      StatusChip(
                        label: 'Nearby helpers',
                        icon: Icons.location_on,
                        textColor: AppColors.cardWhite,
                        backgroundColor: AppColors.inkBlue.withValues(alpha: 0.5),
                      ),
                      StatusChip(
                        label: 'Verified profiles',
                        icon: Icons.check_circle,
                        textColor: AppColors.cardWhite,
                        backgroundColor: AppColors.inkBlue.withValues(alpha: 0.5),
                      ),
                      StatusChip(
                        label: 'AI matching',
                        icon: Icons.bolt,
                        textColor: AppColors.cardWhite,
                        backgroundColor: AppColors.inkBlue.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // CTA Button
                  CustomButton(
                    text: 'Get Started',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.pushNamed(context, '/role_selection');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bottom Text
                  Text(
                    'Built for urgent fixes, home services, and everyday local help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildStatRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedTeal, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.mainText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
