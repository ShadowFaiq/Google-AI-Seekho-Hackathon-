import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // CONFIGURABLE BASE URL
  // Use http://127.0.0.1:8000 for Chrome testing
  // Use http://10.0.2.2:8000 for Android Emulator testing
  static String baseUrl = 'http://127.0.0.1:8000';

  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Submits the service request to the backend.
  /// POSTs to /api/request with user_id and text.
  static Future<Map<String, dynamic>> submitRequest({
    required String userId,
    required String text,
  }) async {
    final url = Uri.parse('$baseUrl/api/request');
    final body = jsonEncode({
      'user_id': userId,
      'text': text,
    });

    debugPrint('ApiService: Request URL: $url');
    debugPrint('ApiService: Request Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeoutDuration);

      debugPrint('ApiService: Response Status Code: ${response.statusCode}');
      debugPrint('ApiService: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: SocketException: $e');
      throw const HttpException('Backend unreachable (SocketException)');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: TimeoutException: $e');
      throw const HttpException('Request timed out connecting to backend');
    } on FormatException catch (e) {
      debugPrint('ApiService: FormatException: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Unexpected error: $e');
      rethrow;
    }
  }

  /// Gets the trace for a specific request ID.
  /// GETs to /api/trace/{req_id}.
  static Future<Map<String, dynamic>> getTrace(String reqId) async {
    final url = Uri.parse('$baseUrl/api/trace/$reqId');

    debugPrint('ApiService: Fetching trace from $url');

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('ApiService: Trace fetch success. Response: $decoded');
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        debugPrint('ApiService: Error response status code: ${response.statusCode}');
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: SocketException - backend not running. Details: $e');
      throw const HttpException('Backend not running or unreachable');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: Request timeout. Details: $e');
      throw const HttpException('Request timed out connecting to backend');
    } on FormatException catch (e) {
      debugPrint('ApiService: Invalid JSON response. Details: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Unknown error occurred. Details: $e');
      rethrow;
    }
  }

  /// Registers a customer.
  /// POSTs to /api/auth/register.
  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });

    debugPrint('ApiService: Registering customer at $url');
    debugPrint('ApiService: Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('ApiService: Registration success. Response: $decoded');
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        debugPrint('ApiService: Registration failed. Status: ${response.statusCode}');
        throw HttpException('Registration endpoint returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: Registration failed - offline: $e');
      throw const HttpException('Backend not running or unreachable');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: Registration timed out: $e');
      throw const HttpException('Connection timed out');
    } on FormatException catch (e) {
      debugPrint('ApiService: Invalid JSON: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Registration error: $e');
      rethrow;
    }
  }

  /// Logins a customer.
  /// POSTs to /api/auth/login.
  static Future<Map<String, dynamic>> loginCustomer({
    required String emailOrPhone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final body = jsonEncode({
      'email': emailOrPhone,
      'password': password,
    });

    debugPrint('ApiService: Logging in customer at $url');
    debugPrint('ApiService: Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('ApiService: Login success. Response: $decoded');
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        debugPrint('ApiService: Login failed. Status: ${response.statusCode}');
        throw HttpException('Login endpoint returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: Login failed - offline: $e');
      throw const HttpException('Backend not running or unreachable');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: Login timed out: $e');
      throw const HttpException('Connection timed out');
    } on FormatException catch (e) {
      debugPrint('ApiService: Invalid JSON: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Login error: $e');
      rethrow;
    }
  }

  /// Submits customer offered price.
  /// POSTs to /api/bids/offer.
  static Future<Map<String, dynamic>> submitBidOffer({
    required String reqId,
    required String userId,
    required double offeredPrice,
    required String sessionToken,
  }) async {
    final url = Uri.parse('$baseUrl/api/bids/offer');
    final body = jsonEncode({
      'req_id': reqId,
      'user_id': userId,
      'offered_price': offeredPrice,
      'session_token': sessionToken,
    });

    debugPrint('ApiService: Submitting bid offer to $url');
    debugPrint('ApiService: Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('ApiService: Bid offer success. Response: $decoded');
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        debugPrint('ApiService: Bid offer failed. Status: ${response.statusCode}');
        throw HttpException('Bids offer endpoint returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: Bid offer failed - offline: $e');
      throw const HttpException('Backend not running or unreachable');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: Bid offer timed out: $e');
      throw const HttpException('Connection timed out');
    } on FormatException catch (e) {
      debugPrint('ApiService: Invalid JSON: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Bid offer error: $e');
      rethrow;
    }
  }

  /// Accepts a provider bid.
  /// POSTs to /api/bids/accept.
  static Future<Map<String, dynamic>> acceptBid({
    required String reqId,
    required String userId,
    required String providerId,
    required double acceptedPrice,
    required String sessionToken,
  }) async {
    final url = Uri.parse('$baseUrl/api/bids/accept');
    final body = jsonEncode({
      'req_id': reqId,
      'user_id': userId,
      'provider_id': providerId,
      'accepted_price': acceptedPrice,
      'session_token': sessionToken,
    });

    debugPrint('ApiService: Accepting bid at $url');
    debugPrint('ApiService: Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('ApiService: Accept bid success. Response: $decoded');
          return decoded;
        } else {
          throw const FormatException('Expected JSON map response');
        }
      } else {
        debugPrint('ApiService: Accept bid failed. Status: ${response.statusCode}');
        throw HttpException('Bids accept endpoint returned status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('ApiService: Accept bid failed - offline: $e');
      throw const HttpException('Backend not running or unreachable');
    } on TimeoutException catch (e) {
      debugPrint('ApiService: Accept bid timed out: $e');
      throw const HttpException('Connection timed out');
    } on FormatException catch (e) {
      debugPrint('ApiService: Invalid JSON: $e');
      throw const FormatException('Failed to parse backend response');
    } catch (e) {
      debugPrint('ApiService: Accept bid error: $e');
      rethrow;
    }
  }

  /// Fetches historical chat messages for a booking.
  /// GETs to /api/chat/{booking_id}/history.
  static Future<List<dynamic>> getChatHistory(String bookingId) async {
    final url = Uri.parse('$baseUrl/api/chat/$bookingId/history');
    debugPrint('ApiService: Fetching chat history from $url');
    try {
      final response = await http.get(url).timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['messages'] ?? [];
      } else {
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService: Failed to fetch chat history: $e');
      rethrow;
    }
  }

  /// Registers a device token for push notifications.
  /// POSTs to /api/notification/register-device-token.
  static Future<Map<String, dynamic>> registerDeviceToken({
    required String userId,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$baseUrl/api/notification/register-device-token');
    final body = jsonEncode({
      'user_id': userId,
      'device_token': deviceToken,
    });
    debugPrint('ApiService: Registering device token at $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService: Failed to register device token: $e');
      rethrow;
    }
  }
}
