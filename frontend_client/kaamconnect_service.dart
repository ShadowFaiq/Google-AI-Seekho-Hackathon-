import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class KaamConnectService {
  final String baseUrl; // E.g., 'http://10.0.2.2:8000'
  final String wsUrl;  // E.g., 'ws://10.0.2.2:8000'
  
  String? jwtToken;
  String? sessionToken;
  IOWebSocketChannel? _chatChannel;

  KaamConnectService({required this.baseUrl, required this.wsUrl});

  // 1. User Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      jwtToken = data['token']; // Save JWT token for authenticated header calls
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // 2. Submit initial request (Gemini extracts boundaries)
  Future<Map<String, dynamic>> submitRequest(String userId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/request'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'user_id': userId, 'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      sessionToken = data['session_token']; // Save session token for bidding steps
      return data;
    } else {
      throw Exception('Request initiation failed: ${response.body}');
    }
  }

  // 3. Place bid offer (returns provider counter-bids list)
  Future<Map<String, dynamic>> placeBidOffer(String reqId, String userId, double offerPrice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bids/offer'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        if (sessionToken != null) 'X-Session-Token': sessionToken!,
      },
      body: jsonEncode({
        'req_id': reqId,
        'user_id': userId,
        'offer_price': offerPrice,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Offer failed: ${response.body}');
    }
  }

  // 4. Accept counter-bid (locks booking)
  Future<Map<String, dynamic>> acceptBid(String reqId, String userId, String providerId, double acceptedPrice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bids/accept'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        if (sessionToken != null) 'X-Session-Token': sessionToken!,
      },
      body: jsonEncode({
        'req_id': reqId,
        'user_id': userId,
        'provider_id': providerId,
        'accepted_price': acceptedPrice,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Accepting bid failed: ${response.body}');
    }
  }

  // 5. Connect to Real-time Chat WebSocket
  void connectChat({
    required String bookingId,
    required String userId,
    required Function(Map<String, dynamic> message) onMessageReceived,
    required Function(dynamic error) onError,
    required Function() onDone,
  }) {
    _chatChannel = IOWebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/chat/$bookingId/$userId'),
    );

    _chatChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data);
        onMessageReceived(decoded);
      },
      onError: onError,
      onDone: onDone,
    );
  }

  // 6. Send message over active Chat WebSocket
  void sendChatMessage(String senderId, String text) {
    if (_chatChannel != null) {
      final payload = {
        'sender_id': senderId,
        'text': text,
      };
      _chatChannel!.sink.add(jsonEncode(payload));
    }
  }

  // 7. Disconnect Chat WebSocket
  void disconnectChat() {
    _chatChannel?.sink.close();
    _chatChannel = null;
  }
}
