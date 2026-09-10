import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';
import 'package:mandap/features/auth/infrastructure/auth_repository.dart';
import 'package:mandap/features/billing/infrastructure/billing_repository.dart';
import 'package:mandap/features/billing/domain/models/entitlement_result.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockBillingRepository extends Mock implements BillingRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockBillingRepository mockBillingRepository;
  late BootstrapCoordinator coordinator;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockBillingRepository = MockBillingRepository();
    coordinator = BootstrapCoordinator(
      authRepository: mockAuthRepository,
      billingRepository: mockBillingRepository,
    );
  });

  test('routes to login when no token exists', () async {
    when(() => mockAuthRepository.initialize()).thenAnswer((_) async {});
    when(() => mockAuthRepository.getAccessToken()).thenAnswer((_) async => null);

    await coordinator.bootstrap();

    expect(coordinator.current.authState, AppAuthState.unauthenticated);
    expect(coordinator.current.destination, AppDestination.login);
  });

  test('routes to verify email when user email is unverified', () async {
    when(() => mockAuthRepository.initialize()).thenAnswer((_) async {});
    when(() => mockAuthRepository.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => mockAuthRepository.getMe()).thenAnswer((_) async => const AuthUser(
      id: '1',
      email: 'test@test.com',
      emailVerified: false,
      mobileVerified: false,
      identityVerified: false,
    ));

    await coordinator.bootstrap();

    expect(coordinator.current.authState, AppAuthState.authenticated);
    expect(coordinator.current.onboardingState, OnboardingState.emailVerificationRequired);
    expect(coordinator.current.destination, AppDestination.verifyEmail);
    verifyNever(() => mockBillingRepository.getEntitlement(any()));
  });

  test('routes to trial setup when user is verified but has no entitlement', () async {
    when(() => mockAuthRepository.initialize()).thenAnswer((_) async {});
    when(() => mockAuthRepository.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => mockAuthRepository.getMe()).thenAnswer((_) async => const AuthUser(
      id: '1',
      email: 'test@test.com',
      emailVerified: true,
      mobileVerified: true,
      identityVerified: true,
      organizationId: 'org_1',
    ));
    when(() => mockBillingRepository.getEntitlement('org_1')).thenAnswer((_) async => const EntitlementResult(
      applicationAccess: false,
      subscriptionStatus: 'PENDING_AUTHORIZATION',
    ));

    await coordinator.bootstrap();

    expect(coordinator.current.authState, AppAuthState.authenticated);
    expect(coordinator.current.onboardingState, OnboardingState.billingAuthorizationRequired);
    expect(coordinator.current.destination, AppDestination.authorizeBilling);
  });

  test('routes to projects when user is verified and has entitlement', () async {
    when(() => mockAuthRepository.initialize()).thenAnswer((_) async {});
    when(() => mockAuthRepository.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => mockAuthRepository.getMe()).thenAnswer((_) async => const AuthUser(
      id: '1',
      email: 'test@test.com',
      emailVerified: true,
      mobileVerified: true,
      identityVerified: true,
      organizationId: 'org_1',
    ));
    when(() => mockBillingRepository.getEntitlement('org_1')).thenAnswer((_) async => const EntitlementResult(
      applicationAccess: true,
      subscriptionStatus: 'TRIALING',
    ));

    await coordinator.bootstrap();

    expect(coordinator.current.authState, AppAuthState.authenticated);
    expect(coordinator.current.onboardingState, OnboardingState.complete);
    expect(coordinator.current.destination, AppDestination.projects);
  });
}
