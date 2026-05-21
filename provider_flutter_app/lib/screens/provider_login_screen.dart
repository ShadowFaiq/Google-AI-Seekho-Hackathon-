import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'provider_dashboard_screen.dart';

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({Key? key}) : super(key: key);

  @override
  _ProviderLoginScreenState createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _emailController = TextEditingController(text: 'ali@kaamconnect.pk');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegisterMode = false;
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'ac_repair');
  final _rateController = TextEditingController(text: '1000');

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProviderDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        serviceCategory: _categoryController.text.trim(),
        baseHourlyRate: double.tryParse(_rateController.text) ?? 1000,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProviderDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Fikar Free',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Provider Partner App',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Connection indicator
              FutureBuilder<bool>(
                future: ApiService.checkConnection(),
                builder: (context, snapshot) {
                  final connected = snapshot.data == true;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        connected ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: connected ? const Color(0xFF10B981) : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connected ? 'Backend Connected' : (snapshot.connectionState == ConnectionState.waiting ? 'Connecting...' : 'Backend Offline (Mock Mode)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: connected ? const Color(0xFF10B981) : Colors.orange,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isRegisterMode) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (_isRegisterMode) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Service Category',
                    prefixIcon: Icon(Icons.category),
                    hintText: 'e.g. ac_repair, plumbing, electrician',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rateController,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (PKR)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : (_isRegisterMode ? _register : _login),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isRegisterMode ? 'Register' : 'Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  _isRegisterMode ? 'Already have an account? Login' : 'New provider? Register here',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
