import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  bool _isLogin = true;
  bool _rememberMe = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Top Branding ──
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/fikrfree_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fikr',
                        style: TextStyle(
                          color: AppColors.cardWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Free',
                        style: TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Less worry. Trusted help nearby.',
                  style: TextStyle(
                    color: AppColors.cardWhite.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Auth Card ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Segmented Tabs
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: AppColors.warmIvory,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isLogin
                                        ? AppColors.cardWhite
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _isLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: _isLogin
                                          ? AppColors.mainText
                                          : AppColors.mutedText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isLogin
                                        ? AppColors.cardWhite
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: !_isLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: !_isLogin
                                          ? AppColors.mainText
                                          : AppColors.mutedText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _isLogin ? _buildLoginTab() : _buildCreateAccountTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.mainText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Access your FikrFree account to request trusted nearby help.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        
        // Email Field
        _buildTextField(
          label: 'Email or Phone',
          hint: 'Enter your registered contact',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        
        // Password Field
        _buildTextField(
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 12),
        
        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    activeColor: AppColors.mutedTeal,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember Me',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showForgotPasswordSheet,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Login Button
        CustomButton(
          text: 'Login',
          onPressed: () {
            Navigator.pushNamed(context, '/user_request');
          },
        ),
        
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        
        // Continue as Guest
        _buildOutlineButton(
          text: 'Continue as Guest',
          icon: Icons.person_outline,
          onPressed: () {
            Navigator.pushNamed(context, '/user_request');
          },
        ),
      ],
    );
  }

  Widget _buildCreateAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field
        _buildTextField(
          label: 'Email or Phone',
          hint: 'Enter your registered contact',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        
        // Password Field
        _buildTextField(
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Use 8+ characters with uppercase, lowercase, number, and special character.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedText.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        
        // Terms Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                activeColor: AppColors.mutedTeal,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Create Account Button
        CustomButton(
          text: 'Create Account',
          onPressed: () {
            Navigator.pushNamed(context, '/profile_setup');
          },
        ),
        
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        
        // Continue as Guest
        _buildOutlineButton(
          text: 'Continue as Guest',
          icon: Icons.person_outline,
          onPressed: () {
            Navigator.pushNamed(context, '/user_request');
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.mainText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword && _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.mutedText, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.mutedText,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.warmIvory.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mutedTeal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedText,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildOutlineButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.mainText,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email and we’ll send reset instructions when backend is connected.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Send Reset Link',
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Password reset flow prepared. Backend connection pending.',
                        style: TextStyle(color: AppColors.cardWhite),
                      ),
                      backgroundColor: AppColors.mutedTeal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
