import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';
import 'widgets/premium_auth_textfield.dart';
import 'widgets/premium_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailOtpController = TextEditingController();

  String _selectedGender = 'Female';
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 1; // 1: Details, 2: Verification

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _emailOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = context.read<AuthRepository>();

      // Split name
      final parts = _nameController.text.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts[0] : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final errorMessage = await authRepo.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: firstName,
        lastName: lastName,
        phone: _phoneController.text,
        gender: _selectedGender,
        aadhaarNumber: _aadhaarController.text,
      );

      if (errorMessage == null) {
        // Success - move to verification
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
        // Send OTP
        await authRepo.sendMobileOtp(_phoneController.text);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  Future<void> _handleVerify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final mobileSuccess = await authRepo.verifyMobileOtp(_phoneController.text, _otpController.text);
    final emailSuccess = await authRepo.verifyEmail(_emailOtpController.text);
    
    if (mobileSuccess && emailSuccess) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid Mobile or Email OTP. Please try again.';
      });
    }
  }

  Widget _buildSectionHeader(String title, {String? subtitle, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                softWrap: true,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Removed Aadhaar Upload section per user request


            // Section 2 — Guest Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Verify Guest Details'),

                  if (isMobile) ...[
                    PremiumAuthTextField(
                      controller: _nameController,
                      labelText: 'Full Legal Name *',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    PremiumAuthTextField(
                      controller: _phoneController,
                      labelText: 'WhatsApp Mobile (+91) *',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    PremiumAuthTextField(
                      controller: _emailController,
                      labelText: 'Email Address *',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    PremiumAuthTextField(
                      controller: _passwordController,
                      labelText: 'Password *',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PremiumAuthTextField(
                            controller: _nameController,
                            labelText: 'Full Legal Name *',
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PremiumAuthTextField(
                            controller: _phoneController,
                            labelText: 'WhatsApp Mobile (+91) *',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumAuthTextField(
                            controller: _emailController,
                            labelText: 'Email Address *',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PremiumAuthTextField(
                            controller: _passwordController,
                            labelText: 'Password *',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_currentStep == 2) ...[
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Account Verification'),
                    Text(
                      'We have sent verification codes to your mobile and email.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    if (isMobile) ...[
                      PremiumAuthTextField(
                        controller: _otpController,
                        labelText: 'Mobile OTP',
                        prefixIcon: Icons.phone_android,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      PremiumAuthTextField(
                        controller: _emailOtpController,
                        labelText: 'Email OTP',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.text,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: PremiumAuthTextField(
                              controller: _otpController,
                              labelText: 'Mobile OTP',
                              prefixIcon: Icons.phone_android,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PremiumAuthTextField(
                              controller: _emailOtpController,
                              labelText: 'Email OTP',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            PremiumAuthButton(
              text: _currentStep == 1 ? 'Create Account' : 'Verify & Continue',
              isLoading: _isLoading,
              onPressed: _currentStep == 1 ? _handleRegister : _handleVerify,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Dark Premium Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.5,
                colors: [
                  Color(0xFF312E81), // Deep Violet
                  Color(0xFF0F172A), // Slate 900
                ],
              ),
            ),
          ),
          
          // Subtle glowing orb effect
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),

          // Main Register Card
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withValues(alpha: 0.2),
                             blurRadius: 30,
                             offset: const Offset(0, 10),
                           )
                        ],
                      ),
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Header
                        const Icon(
                          Icons.how_to_reg_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _currentStep == 1 ? 'Join MANDAP' : 'Verification',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentStep == 1 ? 'Complete your profile to continue' : 'Secure your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
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
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red[200]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Main Content
                        _buildDetailsForm(),
                        
                        if (_currentStep == 1) ...[
                          const SizedBox(height: 32),
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),   // Column
                  ),     // Container
                ),       // BackdropFilter
              ),         // ClipRRect
            ),           // Center
          ),             // SingleChildScrollView
        ),               // SafeArea
        ],
      ),                 // Stack
    );                   // Scaffold
  }
}
