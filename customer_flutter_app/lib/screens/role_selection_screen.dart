import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/status_chip.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Row: Back Arrow + Brand ──
                      Row(
                        children: [
                          // Back arrow
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.inkBlue.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.mutedTeal.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppColors.mutedTeal,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Brand
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.softIvory,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/fikrfree_logo.png',
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Fikr',
                                  style: TextStyle(
                                    color: AppColors.cardWhite,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Free',
                                  style: TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Invisible spacer to balance the row
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 36),

                  // ── Title ──
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'How do you want to use\n',
                          style: TextStyle(
                            color: AppColors.cardWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Fikr',
                          style: TextStyle(
                            color: AppColors.cardWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Free',
                          style: TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: '?',
                          style: TextStyle(
                            color: AppColors.cardWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──
                  Text(
                    'Choose your role to continue.',
                    style: TextStyle(
                      color: AppColors.mutedText.withValues(alpha: 0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Customer Card ──
                  _RoleCard(
                    icon: Icons.person_outline,
                    iconColor: AppColors.mutedTeal,
                    chipLabel: 'CUSTOMER',
                    chipBgColor: AppColors.mutedTeal,
                    chipTextColor: AppColors.cardWhite,
                    title: 'I need help',
                    subtitle: 'Find trusted nearby services in minutes.',
                    detailText:
                        'Create requests, use location, and prepare for AI matching.',
                    borderColor: AppColors.mutedTeal.withValues(alpha: 0.4),
                    cardColor: AppColors.inkBlue.withValues(alpha: 0.5),
                    onTap: () {
                      Navigator.pushNamed(context, '/auth');
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Provider Card ──
                  _RoleCard(
                    icon: Icons.build_outlined,
                    iconColor: AppColors.mutedText,
                    chipLabel: 'PROVIDER',
                    chipBgColor: AppColors.royalSlate,
                    chipTextColor: AppColors.cardWhite,
                    title: 'I provide services',
                    subtitle: 'Get nearby jobs and grow your work.',
                    providerLabel: 'PROVIDER SIDE BY TEAMMATE',
                    borderColor: AppColors.royalSlate.withValues(alpha: 0.5),
                    cardColor: AppColors.royalSlate.withValues(alpha: 0.4),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Provider side will be connected by teammate.',
                            style: TextStyle(color: AppColors.cardWhite),
                          ),
                          backgroundColor: AppColors.royalSlate,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // ── Bottom Dot Indicators ──
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(false),
                        const SizedBox(width: 8),
                        _dot(true),
                        const SizedBox(width: 8),
                        _dot(false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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

  /// Builds a small dot indicator.
  Widget _dot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.mutedTeal
            : AppColors.mutedText.withValues(alpha: 0.4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reusable Role Card widget (private to this file)
// ─────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String chipLabel;
  final Color chipBgColor;
  final Color chipTextColor;
  final String title;
  final String subtitle;
  final String? detailText;
  final String? providerLabel;
  final Color borderColor;
  final Color cardColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.chipLabel,
    required this.chipBgColor,
    required this.chipTextColor,
    required this.title,
    required this.subtitle,
    this.detailText,
    this.providerLabel,
    required this.borderColor,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Chip row
            Row(
              children: [
                // Circular icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
                StatusChip(
                  label: chipLabel,
                  backgroundColor: chipBgColor,
                  textColor: chipTextColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: AppColors.cardWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.mutedText.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Detail text (Customer card only)
            if (detailText != null) ...[
              const SizedBox(height: 14),
              Text(
                detailText!,
                style: TextStyle(
                  color: AppColors.mutedTeal.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],

            // Provider label (Provider card only)
            if (providerLabel != null) ...[
              const SizedBox(height: 12),
              Text(
                providerLabel!,
                style: TextStyle(
                  color: AppColors.mutedText.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
