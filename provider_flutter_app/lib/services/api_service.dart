import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Auto-detect: Android emulator uses 10.0.2.2, web/desktop uses localhost
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String? _jwtToken;
  static String? _providerId;
  static String? _providerName;
  static String? _providerEmail;

  static String? get jwtToken => _jwtToken;
  static String? get providerId => _providerId;
  static String? get providerName => _providerName;
  static String? get providerEmail => _providerEmail;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
  };

  // ── Provider Login ──
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/provider/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _jwtToken = data['token'];
      _providerId = data['provider']['id'];
      _providerName = data['provider']['name'];
      _providerEmail = data['provider']['email'];
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  // ── Provider Register ──
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String serviceCategory,
    required double baseHourlyRate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/provider/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'service_category': serviceCategory,
        'base_hourly_rate': baseHourlyRate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _jwtToken = data['token'];
      _providerId = data['provider']['id'];
      _providerName = data['provider']['name'];
      _providerEmail = data['provider']['email'];
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  // ── Provider Dashboard ──
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/$_providerId/dashboard'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  // ── Toggle Availability ──
  static Future<Map<String, dynamic>> setAvailability(bool available) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/$_providerId/availability?available=$available'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update availability');
    }
  }

  // ── Demand Forecast ──
  static Future<Map<String, dynamic>> getDemandForecast() async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/$_providerId/demand-forecast'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load demand forecast');
    }
  }

  // ── Health check (test connectivity) ──
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/docs'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void logout() {
    _jwtToken = null;
    _providerId = null;
    _providerName = null;
    _providerEmail = null;
  }
}
