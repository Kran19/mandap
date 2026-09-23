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

/// Login screen implementing the V2 phone + password → OTP flow.
///
/// Styled precisely according to the luxury mandap branding design:
/// - Top: "Create Your Structure" + "PLAN · DESIGN · BUILD · VISUALIZE"
/// - Center: Frosted card with Logo, "Welcome", phone & password inputs, maroon Continue button
/// - Bottom: "EVENTS / EXHIBITIONS / STAGES / MANDAPS / AND MORE"
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
          // Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Interactive Form Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Language Selector in top right
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
                        // Top Header: Create Your Structure
                        _buildTopHeader(),
                        const SizedBox(height: 12),

                        _otpStep ? _buildOtpStep(context) : _buildLoginStep(context),
                      ],
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

  Widget _buildTopHeader() {
    return Column(
      children: [
        Text(
          'Create Your Structure',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFamily: 'serif',
            color: const Color(0xFF7A1C28),
            letterSpacing: -0.3,
            shadows: [
              const Shadow(
                color: Colors.white,
                blurRadius: 10,
              ),
              const Shadow(
                color: Colors.white,
                blurRadius: 20,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF881D26),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'PLAN  ·  DESIGN  ·  BUILD  ·  VISUALIZE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            color: const Color(0xFF2C1810),
            shadows: [
              const Shadow(
                color: Colors.white,
                blurRadius: 8,
              ),
              const Shadow(
                color: Colors.white,
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        const SizedBox(height: 14),
        Text(
          l10n?.welcome ?? 'Welcome',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
            shadows: [
              const Shadow(
                color: Colors.white,
                blurRadius: 10,
              ),
              const Shadow(
                color: Colors.white,
                blurRadius: 20,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        PremiumAuthTextField(
          controller: _phoneController,
          labelText: l10n?.phoneNumber ?? 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          fillColor: Colors.white,
          borderRadius: 14,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        PremiumAuthTextField(
          controller: _passwordController,
          labelText: l10n?.password ?? 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          fillColor: Colors.white,
          borderRadius: 14,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n?.forgotPassword ?? 'Forgot password?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: const Color(0xFF2563EB),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        PremiumAuthButton(
          text: l10n?.continueButton ?? 'Continue',
          isLoading: _isLoading,
          onPressed: _handleLogin,
          borderRadius: 12,
          verticalPadding: 12,
          gradientColors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n?.dontHaveAccount ?? "Don't have an account?",
              style: TextStyle(
                color: const Color(0xFF334155),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Text(
                l10n?.createOne ?? 'Create one',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: const Color(0xFF2563EB),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 4,
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
            child: const Icon(Icons.sms_outlined, size: 36, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n?.verifyPhone ?? 'Verify Phone',
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
          '${l10n?.otpSentTo ?? 'We sent a 6-digit code to'}\n${_phoneController.text}',
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

        PremiumAuthTextField(
          controller: _otpController,
          labelText: l10n?.otpLabel ?? '6-Digit OTP',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
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
        const SizedBox(height: 18),
        PremiumAuthButton(
          text: l10n?.verifyAndSignIn ?? 'Verify & Sign In',
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
          borderRadius: 14,
          verticalPadding: 15,
          gradientColors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _goBackToLogin,
          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF334155)),
          label: Text(
            l10n?.changePhoneNumber ?? 'Change phone number',
            style: TextStyle(
              color: const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
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

