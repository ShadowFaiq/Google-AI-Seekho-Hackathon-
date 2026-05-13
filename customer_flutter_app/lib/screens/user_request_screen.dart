import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class UserRequestScreen extends StatefulWidget {
  const UserRequestScreen({super.key});

  @override
  State<UserRequestScreen> createState() => _UserRequestScreenState();
}

class _UserRequestScreenState extends State<UserRequestScreen> {
  final TextEditingController _requestController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedService = 'AC Repair';
  String _selectedTime = 'Today';
  String _selectedBudget = 'Rs. 2000';
  String _selectedUrgency = 'Emergency';

  final List<String> _services = [
    'AC Repair', 'Plumber', 'Electrician', 'Cleaner',
    'Tutor', 'Beautician', 'Mechanic', 'Painter'
  ];

  final List<String> _times = ['Now', 'Today', 'Tomorrow AM', 'Tomorrow PM', 'Custom'];
  final List<String> _budgets = ['Rs. 1000', 'Rs. 2000', 'Rs. 3000', 'Custom'];
  final List<String> _urgencies = ['Normal', 'Urgent', 'Emergency'];

  Future<void> _onPrepareRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String requestText = "$_selectedService needed near Gulberg III, Lahore. Budget $_selectedBudget. Urgency $_selectedUrgency. Preferred time $_selectedTime.";
    if (_requestController.text.trim().isNotEmpty) {
      requestText += " Details: ${_requestController.text.trim()}";
    }

    try {
      final response = await ApiService.submitRequest(
        userId: "U001",
        text: requestText,
      );

      final reqId = response['req_id'] ?? 'FF-92841-A';
      final sessionToken = response['session_token'] ?? 'mock_session_12345';
      final ctx = response['ctx'] as Map<String, dynamic>?;
      final priceBreakdown = ctx != null ? ctx['price_breakdown'] as Map<String, dynamic>? : null;
      
      final suggestedPrice = priceBreakdown != null ? (priceBreakdown['suggested_price'] as num?)?.toDouble() : 1000.0;
      final floorPrice = priceBreakdown != null ? (priceBreakdown['floor_price'] as num?)?.toDouble() : 800.0;
      final ceilingPrice = priceBreakdown != null ? (priceBreakdown['ceiling_price'] as num?)?.toDouble() : 1500.0;

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/bidding',
          arguments: {
            'req_id': reqId,
            'session_token': sessionToken,
            'suggested_price': suggestedPrice,
            'floor_price': floorPrice,
            'ceiling_price': ceilingPrice,
            'ctx': ctx,
          },
        );
      }
    } catch (e) {
      debugPrint('UserRequestScreen: API submit request failed: $e');
      if (mounted) {
        String errMsg = e.toString();
        if (e is HttpException) {
          errMsg = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request API failed: $errMsg'),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushNamed(
          context,
          '/bidding',
          arguments: {
            'req_id': 'FF-92841-A',
            'session_token': 'mock_session_12345',
            'suggested_price': 1000.0,
            'floor_price': 800.0,
            'ceiling_price': 1500.0,
            'ctx': null,
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopAppBar(),
                const SizedBox(height: 24),
                
                _buildHeroCard(),
                const SizedBox(height: 20),
                
                _buildUrgentHelpCard(),
                const SizedBox(height: 28),
                
                _buildSectionHeading('Describe your request'),
                _buildRequestInput(),
                const SizedBox(height: 24),
                
                _buildLocationSection(),
                const SizedBox(height: 28),
                
                _buildSectionHeading('Choose service'),
                _buildServiceGrid(),
                const SizedBox(height: 28),
                
                _buildSectionHeading('Preferred time'),
                _buildChips(_times, _selectedTime, (val) => setState(() => _selectedTime = val)),
                const SizedBox(height: 28),
                
                _buildSectionHeading('Budget'),
                _buildChips(_budgets, _selectedBudget, (val) => setState(() => _selectedBudget = val)),
                const SizedBox(height: 28),
                
                _buildSectionHeading('Urgency'),
                _buildUrgencyChips(),
                const SizedBox(height: 32),
                
                _buildSmartMatchingCard(),
                const SizedBox(height: 20),
                
                _buildAiPipelineCard(),
                const SizedBox(height: 40),
                
                CustomButton(
                  text: _isLoading ? 'Preparing request...' : 'Prepare My Request →',
                  onPressed: _onPrepareRequest,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.softIvory,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
        Row(
          children: [
            Stack(
              children: [
                const Icon(Icons.notifications_none, size: 28, color: AppColors.deepNavy),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.mutedTeal,
              child: Icon(Icons.person, size: 20, color: AppColors.cardWhite),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepNavy, AppColors.mutedTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Welcome',
                style: TextStyle(
                  color: AppColors.cardWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Need help nearby?',
            style: TextStyle(
              color: AppColors.cardWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroChip(Icons.people, '12 helpers nearby'),
              _buildHeroChip(Icons.access_time, 'Avg response: 8 min'),
              _buildHeroChip(Icons.location_on, 'Location ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.cardWhite),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.cardWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentHelpCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.emergencyRed,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Need urgent help?',
                          style: TextStyle(
                            color: AppColors.mainText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pipe leak, power issue, lockout, or emergency fix.',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Emergency',
                      style: TextStyle(
                        color: AppColors.cardWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.mainText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRequestInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _requestController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Example: Kal subah G-13 mein AC technician chahiye, budget 2000 hai',
              hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Urdu, Roman Urdu, and English supported.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Icon(Icons.mic, color: AppColors.mutedTeal, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.mainText),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Gulberg III, Lahore',
            style: TextStyle(
              color: AppColors.mainText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.mutedTeal,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Change', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildServiceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final service = _services[index];
        final isSelected = service == _selectedService;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedService = service),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.mutedTeal.withValues(alpha: 0.1) : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.deepNavy : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.mutedTeal.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle, color: AppColors.deepNavy, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  service,
                  style: TextStyle(
                    color: isSelected ? AppColors.deepNavy : AppColors.mainText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChips(List<String> items, String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.deepNavy : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.deepNavy : AppColors.border,
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? AppColors.cardWhite : AppColors.mainText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _urgencies.map((item) {
        final isSelected = item == _selectedUrgency;
        final isEmergency = item == 'Emergency';
        
        Color bgColor = AppColors.cardWhite;
        Color textColor = AppColors.mainText;
        Color borderColor = AppColors.border;
        
        if (isSelected) {
          bgColor = isEmergency ? AppColors.emergencyRed : AppColors.deepNavy;
          textColor = AppColors.cardWhite;
          borderColor = bgColor;
        }

        return GestureDetector(
          onTap: () => setState(() => _selectedUrgency = item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmartMatchingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softIvory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mutedTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Matching',
            style: TextStyle(
              color: AppColors.mainText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle, 'AI understands your request'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.check_circle, 'Nearby verified helpers are checked'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.check_circle, 'Budget and urgency are considered'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.check_circle, 'Request is prepared for provider dashboard'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedTeal, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.mainText,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiPipelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI matching pipeline',
            style: TextStyle(
              color: AppColors.mainText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPipelineRow('Local save', 'Ready', true),
          _buildPipelineRow('GPS location', 'Ready', true),
          _buildPipelineRow('Backend API', 'Connect later', false),
          _buildPipelineRow('LLM intent', 'Connect later', false),
          _buildPipelineRow('RAG provider search', 'Connect later', false),
          _buildPipelineRow('Provider UI bridge', 'Connect later', false),
        ],
      ),
    );
  }

  Widget _buildPipelineRow(String title, String status, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isReady ? AppColors.successGreen : AppColors.warningRust,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
