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

/// Register screen for V2 phone-first authentication.
/// Step 1: Phone + Password + optional name/email → POST /auth/register
/// Step 2: User logs in to verify phone via OTP (flows to LoginScreen).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationComplete = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Phone number is required.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();

    final parts = _nameController.text.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts[0] : null;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    // Normalize phone: prepend +91 if it looks like a bare 10-digit number
    String normalizedPhone = phone;
    if (!phone.startsWith('+') && phone.length == 10) {
      normalizedPhone = '+91$phone';
    }

    final errorMessage = await authRepo.register(
      phone: normalizedPhone,
      password: password,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      setState(() {
        _isLoading = false;
        _registrationComplete = true;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.headerBorder, width: 1.0),
              boxShadow: AppShadows.cardShadow,
            ),
            child: _registrationComplete
                ? _buildSuccessState()
                : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
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
          'Join MANDAP',
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
          'Enter your details to create a new account',
          style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _phoneController,
          labelText: 'Phone Number *',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        PremiumAuthTextField(
          controller: _passwordController,
          labelText: 'Password *',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 14),
        PremiumAuthTextField(
          controller: _nameController,
          labelText: 'Full Name (optional)',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        PremiumAuthTextField(
          controller: _emailController,
          labelText: 'Email Address (optional)',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        PremiumAuthButton(
          text: 'Create Account',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(foregroundColor: AppColors.trussPrimary),
              child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.flooringLight,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Account Created!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your account has been created. Sign in to verify your phone number and access MANDAP.',
          style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        PremiumAuthButton(
          text: 'Sign In',
          isLoading: false,
          onPressed: () => context.go('/login'),
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
