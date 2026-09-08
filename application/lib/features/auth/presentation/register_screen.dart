import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.5,
                colors: [
                  Color(0xFF312E81),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
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
                      child: _registrationComplete
                          ? _buildSuccessState()
                          : _buildFormState(),
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

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.how_to_reg_rounded, size: 48, color: Colors.white),
        const SizedBox(height: 24),
        const Text(
          'Join MANDAP',
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
          'Enter your phone to create an account',
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _phoneController,
          labelText: 'Phone Number *',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
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
        const SizedBox(height: 28),

        PremiumAuthButton(
          text: 'Create Account',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),

        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account?', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(Icons.check_circle_outline, size: 56, color: Colors.greenAccent),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Account Created!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your account has been created. Sign in to verify your phone number and access MANDAP.',
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
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
