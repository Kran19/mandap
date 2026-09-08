import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';
import 'widgets/premium_auth_textfield.dart';
import 'widgets/premium_auth_button.dart';

/// Login screen implementing the V2 phone + password → OTP flow.
///
/// Step 1: User enters phone + password → POST /auth/login
///         If server returns {otpRequired: true, challengeId}, show OTP input.
/// Step 2: User enters OTP → POST /auth/login/verify-otp
///         On success, tokens are stored and BootstrapCoordinator runs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Two-step state
  bool _otpStep = false;
  String? _challengeId;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final result = await authRepo.login(phone, _passwordController.text);

    if (!mounted) return;

    if (result.otpRequired) {
      _fadeController.reset();
      setState(() {
        _isLoading = false;
        _otpStep = true;
        _challengeId = result.challengeId;
      });
      _fadeController.forward();
    } else if (result.success) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final error = await authRepo.verifyLoginOtp(_challengeId!, otp);

    if (!mounted) return;

    if (error == null) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  void _goBackToLogin() {
    _fadeController.reset();
    setState(() {
      _otpStep = false;
      _challengeId = null;
      _otpController.clear();
      _errorMessage = null;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          // Glow orb
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: _otpStep ? _buildOtpStep() : _buildLoginStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.dashboard_customize_rounded, size: 48, color: Colors.white),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in with your phone number',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        PremiumAuthTextField(
          controller: _passwordController,
          labelText: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            ),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        PremiumAuthButton(
          text: 'Continue',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?", style: TextStyle(color: Colors.white.withOpacity(0.6))),
            TextButton(
              onPressed: () => context.go('/register'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Create one', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sms_outlined, size: 48, color: Color(0xFF818CF8)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify Phone',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to\n${_phoneController.text}',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _otpController,
          labelText: '6-Digit OTP',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        PremiumAuthButton(
          text: 'Verify & Sign In',
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _goBackToLogin,
          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white60),
          label: Text('Change phone number', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red[200]))),
        ],
      ),
    );
  }
}
