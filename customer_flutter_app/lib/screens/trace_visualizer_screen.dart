import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_chip.dart';
import '../services/api_service.dart';

class TraceVisualizerScreen extends StatefulWidget {
  const TraceVisualizerScreen({super.key});

  @override
  State<TraceVisualizerScreen> createState() => _TraceVisualizerScreenState();
}

class _TraceVisualizerScreenState extends State<TraceVisualizerScreen> {
  String? _reqId;
  Map<String, dynamic>? _backendResponse;
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorNote;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _reqId = args['req_id'];
        final ctx = args['ctx'];
        if (ctx is Map<String, dynamic>) {
          _backendResponse = ctx;
        }
        if (_reqId != null && _reqId != 'FF-92841-A') {
          _fetchTrace(_reqId!);
        }
      }
      _initialized = true;
    }
  }

  Future<void> _fetchTrace(String reqId) async {
    setState(() {
      _isLoading = true;
      _errorNote = null;
    });

    try {
      final response = await ApiService.getTrace(reqId);
      setState(() {
        final Map<String, dynamic> merged = Map<String, dynamic>.from(_backendResponse ?? {});
        merged.addAll(response);
        _backendResponse = merged;
      });
    } catch (e) {
      debugPrint('TraceVisualizerScreen: Failed to fetch trace: $e');
      setState(() {
        _errorNote = 'Live backend trace unavailable. Showing demo trace.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Fikr',
                                  style: TextStyle(
                                    color: AppColors.deepNavy,
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
                        ],
                      ),
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.deepNavy,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Main Title & Subtitle ──
                  const Text(
                    'AI Trace Visualizer',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Live orchestration preview',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedText.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.mutedTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Request Summary Card ──
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'AC Repair',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainText,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ID: FF-92841-A',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const StatusChip(
                              label: 'Processing',
                              backgroundColor: AppColors.softIvory,
                              textColor: AppColors.mutedTeal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem('Location', 'Gulberg III, Lahore'),
                            _buildSummaryItem('Urgency', 'Emergency', isUrgent: true),
                            _buildSummaryItem('Budget', 'Rs. 2000'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Timeline Section ──
                  if (_isLoading) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mutedTeal),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: [
                          if (_errorNote != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppColors.emergencyRed.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorNote!,
                                      style: const TextStyle(
                                        color: AppColors.emergencyRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _buildTimelineItem(
                            icon: Icons.check,
                            title: 'Intent Agent',
                            subtitle: '91% Confidence',
                            description: 'Detected service need from customer request.',
                            isComplete: true,
                            isLast: false,
                          ),
                          _buildTimelineItem(
                            icon: Icons.translate,
                            title: 'Language Engine',
                            description: 'Urdu, Roman Urdu, and English input supported.',
                            isComplete: true,
                            isLast: false,
                          ),
                          _buildTimelineItem(
                            icon: Icons.person_search_outlined,
                            title: 'Provider Scan',
                            description: 'Scanning nearby verified providers. Found 12 eligible helpers within 5km.',
                            isComplete: true,
                            isLast: false,
                          ),
                          _buildTimelineItem(
                            icon: Icons.hub_outlined,
                            title: '6-Factor Matching',
                            description: 'Ranking by distance, rating, cancellation rate, on-time score, base rate, and urgency.',
                            isComplete: false,
                            isRunning: true,
                            isLast: false,
                          ),
                          _buildTimelineItem(
                            icon: Icons.receipt_long_outlined,
                            title: 'Receipt Generation',
                            description: 'Price estimate and service details compiled.',
                            isComplete: false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Floating Bottom Button ──
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: CustomButton(
                text: 'View Price Breakdown →',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/receipt',
                    arguments: {
                      'backend_response': _backendResponse,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isUrgent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isUrgent ? AppColors.emergencyRed : AppColors.mainText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required String description,
    required bool isComplete,
    bool isRunning = false,
    required bool isLast,
  }) {
    Color iconBgColor = AppColors.divider;
    Color iconColor = AppColors.mutedText;
    Color lineColor = AppColors.divider;

    if (isComplete) {
      iconBgColor = AppColors.mutedTeal;
      iconColor = AppColors.cardWhite;
      lineColor = AppColors.mutedTeal;
    } else if (isRunning) {
      iconBgColor = AppColors.mutedTeal.withValues(alpha: 0.2);
      iconColor = AppColors.mutedTeal;
      lineColor = AppColors.mutedTeal.withValues(alpha: 0.3);
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.mainText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mutedTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (isRunning) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.mutedTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedText.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
      ],
    );

    if (isRunning) {
      content = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mutedTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mutedTeal.withValues(alpha: 0.2)),
        ),
        child: content,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
