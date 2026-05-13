import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final TextEditingController _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _initialized = false;
  String _reqId = 'FF-92841-A';
  String _sessionToken = 'mock_session_12345';
  double _suggestedPrice = 1000.0;
  double _floorPrice = 800.0;
  double _ceilingPrice = 1500.0;

  bool _isLoading = false;
  bool _bidPlaced = false;
  List<Map<String, dynamic>> _bids = [];

  bool _bookingConfirmed = false;
  String _bookingId = '';
  String _bookingSlot = '';
  String _acceptedProvider = '';
  double _acceptedPrice = 1000.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _reqId = args['req_id'] ?? 'FF-92841-A';
        _sessionToken = args['session_token'] ?? 'mock_session_12345';
        _suggestedPrice = args['suggested_price'] ?? 1000.0;
        _floorPrice = args['floor_price'] ?? 800.0;
        _ceilingPrice = args['ceiling_price'] ?? 1500.0;
      }
      _priceController.text = _suggestedPrice.toStringAsFixed(0);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    // Real bid APIs pending backend routes: /api/bids/offer and /api/bids/accept
    if (!_formKey.currentState!.validate()) return;

    final price = double.parse(_priceController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.submitBidOffer(
        reqId: _reqId,
        userId: 'U001',
        offeredPrice: price,
        sessionToken: _sessionToken,
      );

      final bidsList = response['bids'] as List<dynamic>?;
      setState(() {
        if (bidsList != null && bidsList.isNotEmpty) {
          _bids = bidsList.map((b) => {
            'provider_id': b['provider_id']?.toString() ?? 'prov_1',
            'name': b['name']?.toString() ?? 'Provider Tech',
            'bid_price': (b['bid_price'] as num?)?.toDouble() ?? price,
          }).toList();
        } else {
          // Fallback if empty array returned
          _bids = [
            {'provider_id': 'prov_1', 'name': 'Ali Tech (Premium)', 'bid_price': price - 50.0},
            {'provider_id': 'prov_2', 'name': 'Karamat AC Care', 'bid_price': price},
          ];
        }
        _bidPlaced = true;
      });
    } catch (e) {
      debugPrint('BiddingScreen: Bid offer failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bidding backend endpoint pending. Showing demo bids.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _bids = [
          {'provider_id': 'prov_1', 'name': 'Ali Tech (Premium)', 'bid_price': price - 50.0},
          {'provider_id': 'prov_2', 'name': 'Karamat AC Care', 'bid_price': price},
          {'provider_id': 'prov_3', 'name': 'Islamabad Express Fix', 'bid_price': price + 100.0},
        ];
        _bidPlaced = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptProviderBid(String providerId, String providerName, double bidPrice) async {
    // Real bid APIs pending backend routes: /api/bids/offer and /api/bids/accept
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.acceptBid(
        reqId: _reqId,
        userId: 'U001',
        providerId: providerId,
        acceptedPrice: bidPrice,
        sessionToken: _sessionToken,
      );

      final ctx = response['ctx'];
      setState(() {
        _bookingConfirmed = true;
        _bookingId = ctx?['booking_id']?.toString() ?? 'BK-991823';
        _bookingSlot = ctx?['slot']?.toString() ?? '12:00 PM';
        _acceptedProvider = providerName;
        _acceptedPrice = bidPrice;
      });
    } catch (e) {
      debugPrint('BiddingScreen: Accept bid failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accept bid backend pending. Locking booking in demo mode.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _bookingConfirmed = true;
        _bookingId = 'BK-${10000 + (DateTime.now().millisecondsSinceEpoch % 90000)}';
        _bookingSlot = '12:00 PM';
        _acceptedProvider = providerName;
        _acceptedPrice = bidPrice;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.mainText, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Price Match Hub',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!_bookingConfirmed) ...[
                _buildPriceRangeCard(),
                const SizedBox(height: 24),
                if (!_bidPlaced) _buildBidInputForm() else _buildBidsListSection(),
              ] else
                _buildBookingConfirmedSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeCard() {
    return Container(
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
          const Text(
            'Recommended Price Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceStat('Floor Price', 'Rs. ${_floorPrice.toStringAsFixed(0)}', Colors.grey),
              _buildPriceStat('Suggested', 'Rs. ${_suggestedPrice.toStringAsFixed(0)}', AppColors.mutedTeal),
              _buildPriceStat('Ceiling Price', 'Rs. ${_ceilingPrice.toStringAsFixed(0)}', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStat(String label, String value, Color highlightColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlightColor == AppColors.mutedTeal ? AppColors.deepNavy : highlightColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBidInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Name Your Price',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.mainText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter an offered price within the range. Verified helpers will receive your request and bid accordingly.',
            style: TextStyle(fontSize: 13, color: AppColors.mutedText, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
              labelText: 'Offered Price',
              labelStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
              filled: true,
              fillColor: AppColors.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.mutedTeal, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a price';
              }
              final price = double.tryParse(value);
              if (price == null) {
                return 'Please enter a valid number';
              }
              if (price < _floorPrice) {
                return 'Price cannot be lower than floor Rs. ${_floorPrice.toStringAsFixed(0)}';
              }
              if (price > _ceilingPrice) {
                return 'Price cannot exceed ceiling Rs. ${_ceilingPrice.toStringAsFixed(0)}';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: _isLoading ? 'Analyzing price proposal...' : 'Place Bid →',
            onPressed: _submitBid,
          ),
        ],
      ),
    );
  }

  Widget _buildBidsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Provider Bids',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.mainText),
            ),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mutedTeal),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a verified local helper matching your request. Tapping accept locks the service rate.',
          style: TextStyle(fontSize: 13, color: AppColors.mutedText, height: 1.4),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bids.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bid = _bids[index];
            final price = bid['bid_price'] as double;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid['name'] ?? 'Provider Tech',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '4.8 (Verified Helper)',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Rs. ${price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _acceptProviderBid(bid['provider_id'], bid['name'], price),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mutedTeal,
                          foregroundColor: AppColors.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingConfirmedSection() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 80),
          const SizedBox(height: 16),
          const Text(
            'Booking Locked!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.mainText),
          ),
          const SizedBox(height: 8),
          Text(
            'Helper allocation is successfully scheduled.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildConfirmRow('Booking ID', _bookingId),
                const Divider(height: 24, color: AppColors.border),
                _buildConfirmRow('Assigned Helper', _acceptedProvider),
                const Divider(height: 24, color: AppColors.border),
                _buildConfirmRow('Scheduled Slot', _bookingSlot),
                const Divider(height: 24, color: AppColors.border),
                _buildConfirmRow('Agreed Rate', 'Rs. ${_acceptedPrice.toStringAsFixed(0)}'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'View AI Orchestration Trace →',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/trace_visualizer',
                arguments: {
                  'req_id': _reqId,
                  'ctx': {
                    'price_breakdown': {
                      'total_price': _acceptedPrice,
                      'base_service_fee': _acceptedPrice - 500.0,
                      'distance_surcharge': 200.0,
                      'urgency_adjustment': 300.0,
                      'platform_fee': 0.0,
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.mutedText, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.mainText, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
