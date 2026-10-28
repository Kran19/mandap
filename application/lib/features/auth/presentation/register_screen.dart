import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/premium_auth_textfield.dart';
import 'widgets/premium_auth_button.dart';
import 'widgets/six_digit_otp_input.dart';

/// Register screen for V2 phone-first authentication.
/// Step 1: Phone + Password + optional name/email → POST /auth/register
/// Step 2: 6-Box OTP verification directly on screen → verify & auto sign-in.
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
  final _otpController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationComplete = false;

  // OTP Step State
  bool _otpStep = false;
  String? _challengeId;
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _isResending = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _handleResendRegistrationOtp() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final authRepo = context.read<AuthRepository>();
    final result = await authRepo.login(phone, password);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (result.otpRequired) {
      setState(() {
        _challengeId = result.challengeId;
        _otpController.clear();
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new 6-digit OTP has been sent to $phone'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _errorMessage = result.errorMessage ?? 'Failed to resend OTP.');
    }
  }

  Future<void> _handleVerifyRegistrationOtp() async {
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
      _resendTimer?.cancel();
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
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

    final name = _nameController.text.trim();
    final parts = name.isNotEmpty ? name.split(RegExp(r'\s+')) : <String>[];
    final firstName = parts.isNotEmpty ? parts[0] : null;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    // Normalize phone: prepend +91 if it looks like a bare 10-digit number
    String normalizedPhone = phone;
    if (!phone.startsWith('+') && phone.length == 10) {
      normalizedPhone = '+91$phone';
    }

    final result = await authRepo.register(
      phone: normalizedPhone,
      password: password,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (result.success) {
      if (result.challengeId != null) {
        setState(() {
          _isLoading = false;
          _otpStep = true;
          _challengeId = result.challengeId;
        });
        _startResendTimer();
      } else {
        setState(() {
          _isLoading = false;
          _registrationComplete = true;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E0A0D), Color(0xFF0F172A), Color(0xFF020617)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // Interactive Form Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () => LanguageSelectorDialog.show(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.watch<LocaleNotifier>().currentLanguage.flag,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.watch<LocaleNotifier>().currentLanguage.nativeName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_otpStep)
                        _buildOtpStep(context)
                      else if (_registrationComplete)
                        _buildSuccessState(context)
                      else
                        _buildFormState(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 36, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n?.verifyPhone ?? 'Verify Your Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit verification code to\n${_phoneController.text}${_emailController.text.isNotEmpty ? ' and ${_emailController.text}' : ''}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 6,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        SixDigitOtpInput(
          initialValue: _otpController.text,
          onChanged: (val) {
            setState(() {
              _otpController.text = val;
              _errorMessage = null;
            });
          },
          onCompleted: (val) {
            _otpController.text = val;
            _handleVerifyRegistrationOtp();
          },
        ),
        const SizedBox(height: 18),

        // 60-Second Resend Countdown Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_resendCountdown > 0) ...[
              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Resend code in 00:${_resendCountdown.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const Text(
                "Didn't receive code? ",
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: _isResending ? null : _handleResendRegistrationOtp,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend OTP',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        PremiumAuthButton(
          text: 'Verify & Complete Registration',
          isLoading: _isLoading,
          onPressed: _handleVerifyRegistrationOtp,
          borderRadius: 14,
          verticalPadding: 15,
          gradientColors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            _resendTimer?.cancel();
            setState(() {
              _otpStep = false;
              _challengeId = null;
              _otpController.clear();
              _errorMessage = null;
              _resendCountdown = 60;
            });
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF334155)),
          label: const Text(
            'Edit registration details',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF881D26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.joinMandap ?? 'Join MANDAP',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 10,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 20,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.joinSubtitle ?? 'Enter your details to create a new account',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 8,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _phoneController,
          labelText: l10n?.phoneNumberRequired ?? 'Phone Number *',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          fillColor: Colors.white,
          borderRadius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        PremiumAuthTextField(
          controller: _passwordController,
          labelText: l10n?.passwordRequired ?? 'Password *',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          fillColor: Colors.white,
          borderRadius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PremiumAuthTextField(
          controller: _nameController,
          labelText: l10n?.fullNameOptional ?? 'Full Name (optional)',
          prefixIcon: Icons.person_outline,
          fillColor: Colors.white,
          borderRadius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PremiumAuthTextField(
          controller: _emailController,
          labelText: l10n?.emailOptional ?? 'Email (optional)',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          fillColor: Colors.white,
          borderRadius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        const SizedBox(height: 20),

        PremiumAuthButton(
          text: l10n?.createAccount ?? 'Create Account',
          isLoading: _isLoading,
          onPressed: _handleRegister,
          borderRadius: 14,
          verticalPadding: 15,
          gradientColors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),

        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n?.alreadyHaveAccount ?? 'Already have an account?',
              style: TextStyle(
                color: const Color(0xFF334155),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                l10n?.signIn ?? 'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: const Color(0xFF2563EB),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n?.accountCreated ?? 'Account Created!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.accountCreatedSubtitle ?? 'Your account has been set up successfully.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 8,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PremiumAuthButton(
          text: l10n?.signIn ?? 'Sign In',
          isLoading: false,
          onPressed: () => context.go('/login'),
          borderRadius: 14,
          verticalPadding: 15,
          gradientColors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
