import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final backendResponse = args?['backend_response'] as Map<String, dynamic>?;

    String baseServiceFee = 'Rs. 1500';
    String distanceSurcharge = 'Rs. 300';
    String urgencyAdjustment = 'Rs. 500';
    String platformFee = 'Rs. 0';
    String totalPrice = 'Rs. 2300';

    if (backendResponse != null) {
      final priceBreakdown = backendResponse['price_breakdown'] as Map<String, dynamic>?;
      if (priceBreakdown != null) {
        String formatVal(dynamic val) {
          if (val is num) {
            return 'Rs. ${val.toStringAsFixed(0)}';
          }
          return 'Rs. $val';
        }
        if (priceBreakdown['base_service_fee'] != null) {
          baseServiceFee = formatVal(priceBreakdown['base_service_fee']);
        }
        if (priceBreakdown['distance_surcharge'] != null) {
          distanceSurcharge = formatVal(priceBreakdown['distance_surcharge']);
        }
        if (priceBreakdown['urgency_adjustment'] != null) {
          urgencyAdjustment = formatVal(priceBreakdown['urgency_adjustment']);
        }
        if (priceBreakdown['platform_fee'] != null) {
          platformFee = formatVal(priceBreakdown['platform_fee']);
        }
        if (priceBreakdown['total_price'] != null) {
          totalPrice = formatVal(priceBreakdown['total_price']);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top App Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.mainText,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                           Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.softIvory,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/fikrfree_logo.png',
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
                                    color: AppColors.deepNavy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Free',
                                  style: TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.save_alt_outlined,
                        color: AppColors.deepNavy,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Main Heading ──
                  const Text(
                    'Price Breakdown',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.mutedTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated cost prepared by FikrFree AI.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Service Details Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Stack(
                      children: [
                        // Background transparent icon
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.home_repair_service_outlined,
                            size: 48,
                            color: AppColors.mutedText.withValues(alpha: 0.15),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'AC Repair',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainText,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.emergencyRed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'EMERGENCY',
                                    style: TextStyle(
                                      color: AppColors.emergencyRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppColors.mutedText, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Gulberg III, Lahore',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'User Budget',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        totalPrice,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.mainText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Availability',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Available Now',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.successGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Estimated Receipt Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.mutedTeal.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Estimated Receipt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildReceiptRow('Base service fee', baseServiceFee),
                        const SizedBox(height: 14),
                        _buildReceiptRow('Distance surcharge', distanceSurcharge),
                        const SizedBox(height: 14),
                        _buildReceiptRow('Urgency adjustment', urgencyAdjustment),
                        const SizedBox(height: 14),
                        _buildReceiptRow('Platform/demo fee', platformFee, isFree: platformFee.contains('Rs. 0') || platformFee == '0'),
                        
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL ESTIMATE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            Text(
                              totalPrice,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedTeal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Disclaimer Note ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mutedTeal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mutedTeal.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.mutedTeal,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This breakdown is based on the service scope provided. The final price may change after provider confirmation and on-site assessment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedTeal.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Fixed Done Button ──
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: CustomButton(
                text: 'Back to Dashboard',
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/user_request'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isFree ? AppColors.mutedTeal : AppColors.mainText,
          ),
        ),
      ],
    );
  }
}
