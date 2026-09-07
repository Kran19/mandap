import '../domain/models/auth_state.dart';
import '../infrastructure/auth_repository.dart';
import '../../billing/infrastructure/billing_repository.dart';
import '../../billing/domain/models/entitlement_result.dart';
import '../domain/models/auth_user.dart';
import 'package:flutter/foundation.dart';

class BootstrapResult {
  final AppAuthState authState;
  final OnboardingState onboardingState;
  final AppDestination destination;
  final AuthUser? user;
  final EntitlementResult? entitlement;

  const BootstrapResult({
    required this.authState,
    required this.onboardingState,
    required this.destination,
    this.user,
    this.entitlement,
  });
}

class BootstrapCoordinator extends ChangeNotifier {
  final AuthRepository authRepository;
  final BillingRepository billingRepository;

  BootstrapResult _current = const BootstrapResult(
    authState: AppAuthState.initializing,
    onboardingState: OnboardingState.blocked,
    destination: AppDestination.loading,
  );

  BootstrapResult get current => _current;

  BootstrapCoordinator({
    required this.authRepository,
    required this.billingRepository,
  });

  Future<void> bootstrap() async {
    // 1. Session Restoration
    await authRepository.initialize();
    final token = await authRepository.getAccessToken();

    if (token == null) {
      _current = const BootstrapResult(
        authState: AppAuthState.unauthenticated,
        onboardingState: OnboardingState.blocked,
        destination: AppDestination.login,
      );
      notifyListeners();
      return;
    }

    // 2. Resolve Auth User
    final user = await authRepository.getMe();
    if (user == null) {
      // 401 or refresh failure
      _current = const BootstrapResult(
        authState: AppAuthState.authBlocked,
        onboardingState: OnboardingState.blocked,
        destination: AppDestination.login,
      );
      notifyListeners();
      return;
    }

    // 3. Evaluate Verification State
    if (!user.emailVerified) {
      _current = BootstrapResult(
        authState: AppAuthState.authenticated,
        onboardingState: OnboardingState.emailVerificationRequired,
        destination: AppDestination.verifyEmail,
        user: user,
      );
      notifyListeners();
      return;
    }

    if (!user.mobileVerified) {
      _current = BootstrapResult(
        authState: AppAuthState.authenticated,
        onboardingState: OnboardingState.mobileVerificationRequired,
        destination: AppDestination.verifyMobile,
        user: user,
      );
      notifyListeners();
      return;
    }

    // Removed identity verification step as Aadhaar is collected during registration

    // 4. Resolve Entitlement
    if (user.organizationId == null) {
      // User has no organization (should only happen for older test accounts before the auto-org creation fix)
      _current = BootstrapResult(
        authState: AppAuthState.authenticated,
        onboardingState: OnboardingState.blocked,
        destination: AppDestination.blocked,
        user: user,
      );
      notifyListeners();
      return;
    }

    final entitlement = await billingRepository.getEntitlement(user.organizationId!);
    
    if (entitlement == null) {
       // Network error or organization issue
       _current = BootstrapResult(
        authState: AppAuthState.authenticated,
        onboardingState: OnboardingState.blocked,
        destination: AppDestination.blocked,
        user: user,
      );
      notifyListeners();
      return;
    }

    AppDestination finalDestination;
    OnboardingState finalOnboardingState;

    if (!entitlement.applicationAccess) {
      final status = entitlement.subscriptionStatus;
      if (status == null || status == 'PENDING_AUTHORIZATION' || status == 'CANCELLED' || status == 'EXPIRED') {
        finalDestination = AppDestination.authorizeBilling;
        finalOnboardingState = OnboardingState.billingAuthorizationRequired;
      } else if (status == 'PAST_DUE' || status == 'RESTRICTED') {
        finalDestination = AppDestination.authorizeBilling;
        finalOnboardingState = OnboardingState.billingActionRequired;
      } else {
        finalDestination = AppDestination.authorizeBilling;
        finalOnboardingState = OnboardingState.blocked;
      }
    } else {
      // applicationAccess == true -> ACTIVE or TRIALING
      finalDestination = AppDestination.projects;
      finalOnboardingState = OnboardingState.complete;
    }

    _current = BootstrapResult(
      authState: AppAuthState.authenticated,
      onboardingState: finalOnboardingState,
      destination: finalDestination,
      user: user,
      entitlement: entitlement,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await authRepository.clearTokens();
    _current = const BootstrapResult(
      authState: AppAuthState.unauthenticated,
      onboardingState: OnboardingState.blocked,
      destination: AppDestination.login,
    );
    notifyListeners();
  }
}
