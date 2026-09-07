import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final success = await authRepo.verifyEmail(_tokenController.text);

    if (success) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap(); // Automatically moves to next step
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired email verification token.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: () => context.read<BootstrapCoordinator>().logout(),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Check your inbox', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('Please enter the verification code sent to your email to continue.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Verification Code', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
