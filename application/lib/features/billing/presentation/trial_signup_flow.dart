import 'package:flutter/material.dart';

class TrialSignupFlow extends StatefulWidget {
  const TrialSignupFlow({super.key});

  @override
  State<TrialSignupFlow> createState() => _TrialSignupFlowState();
}

class _TrialSignupFlowState extends State<TrialSignupFlow> {
  int _currentStep = 0;
  
  // State for step 1
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  bool _emailVerified = false;

  // State for step 2
  final _mobileController = TextEditingController();
  final _mobileCodeController = TextEditingController();
  bool _mobileVerified = false;

  // State for step 3
  final _identityController = TextEditingController();
  bool _identityVerified = false;

  // State for step 4
  bool _mandateAuthorized = false;
  bool _isProcessing = false;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _verifyEmail() async {
    setState(() => _isProcessing = true);
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _emailVerified = true;
      _isProcessing = false;
    });
    _nextStep();
  }

  Future<void> _verifyMobile() async {
    setState(() => _isProcessing = true);
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _mobileVerified = true;
      _isProcessing = false;
    });
    _nextStep();
  }

  Future<void> _verifyIdentity() async {
    setState(() => _isProcessing = true);
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _identityVerified = true;
      _isProcessing = false;
    });
    _nextStep();
  }

  Future<void> _authorizeAutoPay() async {
    setState(() => _isProcessing = true);
    // Mock Razorpay SDK integration
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _mandateAuthorized = true;
      _isProcessing = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your 7-day free trial has been established!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Go to Dashboard'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start 7-Day Free Trial'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && !_emailVerified) {
            _verifyEmail();
          } else if (_currentStep == 1 && !_mobileVerified) {
            _verifyMobile();
          } else if (_currentStep == 2 && !_identityVerified) {
            _verifyIdentity();
          } else if (_currentStep == 3 && !_mandateAuthorized) {
            _authorizeAutoPay();
          } else {
            _nextStep();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _isProcessing ? null : details.onStepContinue,
                  child: _isProcessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_currentStep == 3 ? 'Authorize AutoPay' : 'Continue'),
                ),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isProcessing ? null : details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Email Verification'),
            subtitle: _emailVerified ? const Text('Verified', style: TextStyle(color: Colors.green)) : null,
            content: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  enabled: !_emailVerified,
                ),
                if (!_emailVerified) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCodeController,
                    decoration: const InputDecoration(labelText: 'Verification Code'),
                  ),
                ]
              ],
            ),
            isActive: _currentStep >= 0,
            state: _emailVerified ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Mobile Verification'),
            subtitle: _mobileVerified ? const Text('Verified', style: TextStyle(color: Colors.green)) : null,
            content: Column(
              children: [
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  enabled: !_mobileVerified,
                ),
                if (!_mobileVerified) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mobileCodeController,
                    decoration: const InputDecoration(labelText: 'OTP'),
                  ),
                ]
              ],
            ),
            isActive: _currentStep >= 1,
            state: _mobileVerified ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Identity Verification'),
            subtitle: _identityVerified ? const Text('Verified', style: TextStyle(color: Colors.green)) : null,
            content: Column(
              children: [
                const Text('Provide an identity reference (e.g. Aadhaar/PAN mapping via secure partner) to prevent trial abuse. Data is protected by our privacy policy.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _identityController,
                  decoration: const InputDecoration(labelText: 'Identity Reference'),
                  enabled: !_identityVerified,
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: _identityVerified ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Payment Authorization'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Set up AutoPay using Razorpay.'),
                SizedBox(height: 8),
                Text('You will not be charged today. After 7 days, your selected plan will automatically renew unless cancelled.'),
              ],
            ),
            isActive: _currentStep >= 3,
            state: _mandateAuthorized ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
