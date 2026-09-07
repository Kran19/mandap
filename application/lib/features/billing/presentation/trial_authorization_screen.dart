import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../infrastructure/billing_repository.dart';
import '../../auth/application/bootstrap_coordinator.dart';

class TrialAuthorizationScreen extends StatefulWidget {
  const TrialAuthorizationScreen({super.key});

  @override
  State<TrialAuthorizationScreen> createState() => _TrialAuthorizationScreenState();
}

class _TrialAuthorizationScreenState extends State<TrialAuthorizationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _plans = [];
  String? _selectedPlanId;
  final _identityController = TextEditingController();

  // Razorpay integration placeholder logic
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    final billingRepo = context.read<BillingRepository>();
    final plans = await billingRepo.getActivePlans();
    
    setState(() {
      _plans = plans;
      if (plans.isNotEmpty) {
         _selectedPlanId = plans.first['id'];
      }
      _isLoading = false;
    });
  }

  Future<void> _handleStartTrial() async {
    if (_selectedPlanId == null || _identityController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a plan and confirm your identity reference.';
      });
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
    });

    final coordinator = context.read<BootstrapCoordinator>();
    final billingRepo = context.read<BillingRepository>();
    
    final result = await billingRepo.setupTrial(
      organizationId: coordinator.current.user!.organizationId!,
      planId: _selectedPlanId!,
      identityReference: _identityController.text,
      idempotencyKey: DateTime.now().millisecondsSinceEpoch.toString(), // Simplified for UI
    );

    if (result != null && result['status'] == 'PENDING_AUTHORIZATION') {
      // Typically we'd open the Razorpay Checkout UI here:
      // Razorpay checkout = Razorpay();
      // checkout.open(result['razorpayOptions']);
      // On success/failure, we poll/refresh the coordinator.

      // For this UI scaffolding, we simulate returning and checking state:
      await Future.delayed(const Duration(seconds: 2));
      await coordinator.bootstrap();
    } else {
      setState(() {
        _isProcessingPayment = false;
        _errorMessage = 'Failed to setup trial. Please check eligibility.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Start Free Trial', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    margin: const EdgeInsets.all(24.0),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 64,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Choose Your Plan',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Experience full premium features. You will not be charged during the 7-day free trial.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
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
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),

                        DropdownButtonFormField<String>(
                          value: _selectedPlanId,
                          dropdownColor: const Color(0xFF1E1B4B),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Select Plan',
                            labelStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: _plans.map((plan) {
                            return DropdownMenuItem<String>(
                              value: plan['id'],
                              child: Text('${plan['name']} - ₹${plan['monthlyPrice']}/mo'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPlanId = val;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        TextField(
                          controller: _identityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Identity Reference (Aadhaar/PAN)',
                            labelStyle: const TextStyle(color: Colors.white54),
                            hintText: 'e.g. AAAAA0000A',
                            hintStyle: const TextStyle(color: Colors.white24),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                        ),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isProcessingPayment ? null : _handleStartTrial,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.blueAccent.withOpacity(0.5),
                          ),
                          child: _isProcessingPayment 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Start 7-Day Free Trial',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: Colors.white54),
                            SizedBox(width: 8),
                            Text('Secured by AutoPay via Razorpay', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
