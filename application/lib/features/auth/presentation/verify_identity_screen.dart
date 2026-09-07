import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../infrastructure/auth_repository.dart';
import '../application/bootstrap_coordinator.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _identityController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final success = await authRepo.verifyIdentity(_identityController.text);

    if (success) {
      final coordinator = context.read<BootstrapCoordinator>();
      await coordinator.bootstrap(); // Automatically moves to next step (Billing/Projects)
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Identity verification failed. Please check your reference number.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Identity Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('Please provide your identity reference (e.g., Aadhaar, PAN) for verification.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              TextField(
                controller: _identityController,
                decoration: const InputDecoration(labelText: 'Identity Reference', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
