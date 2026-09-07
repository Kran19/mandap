import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';

class VerifyMobileScreen extends StatefulWidget {
  const VerifyMobileScreen({super.key});

  @override
  State<VerifyMobileScreen> createState() => _VerifyMobileScreenState();
}

class _VerifyMobileScreenState extends State<VerifyMobileScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final success = await authRepo.sendMobileOtp(_phoneController.text);

    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
      } else {
        _errorMessage = 'Failed to send OTP. Please check the number.';
      }
    });
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final success = await authRepo.verifyMobileOtp(_phoneController.text, _otpController.text);

    if (success) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap(); // Automatically moves to next step
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Mobile')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Mobile Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                _otpSent ? 'Enter the OTP sent to your mobile.' : 'Enter your mobile number to receive an OTP.', 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                enabled: !_otpSent,
                keyboardType: TextInputType.phone,
              ),
              
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'OTP Code', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
