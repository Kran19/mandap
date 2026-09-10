import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';
import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.appBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.headerBorder, width: 1.0),
                boxShadow: AppShadows.cardShadow,
              ),
              child: _otpStep ? _buildOtpStep() : _buildLoginStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.trussLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.architecture_rounded, color: AppColors.trussPrimary, size: 36),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in with your phone number to access MANDAP',
          style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

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
              foregroundColor: AppColors.trussPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            ),
            child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        PremiumAuthButton(
          text: 'Continue',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account?", style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            TextButton(
              onPressed: () => context.go('/register'),
              style: TextButton.styleFrom(foregroundColor: AppColors.trussPrimary),
              child: const Text('Create one', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.trussLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, size: 40, color: AppColors.trussPrimary),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify Phone',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit code to\n${_phoneController.text}',
          style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _otpController,
          labelText: '6-Digit OTP',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        PremiumAuthButton(
          text: 'Verify & Sign In',
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _goBackToLogin,
          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.secondaryText),
          label: const Text('Change phone number', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }
}
