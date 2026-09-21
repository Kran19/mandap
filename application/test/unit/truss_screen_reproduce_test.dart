import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';
import 'package:mandap/features/mandap/presentation/mandap_editor_screen.dart';
import 'package:mandap/features/mandap/presentation/widgets/simplified_truss_rail.dart';
import 'package:mandap/features/mandap/presentation/widgets/in_model_dimension_badge.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_view.dart';

class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Reproduce Truss Screen blank issue with route parameters', (tester) async {
    final mockCoordinator = MockBootstrapCoordinator();
    when(() => mockCoordinator.logout()).thenAnswer((_) async {});
    when(() => mockCoordinator.current).thenReturn(
      const BootstrapResult(
        authState: AppAuthState.authenticated,
        onboardingState: OnboardingState.complete,
        destination: AppDestination.projects,
        user: AuthUser(
          id: 'usr_test',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'Designer',
          emailVerified: true,
          mobileVerified: true,
          identityVerified: true,
          organizationId: 'org_test',
        ),
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoordinator),
        ],
        child: const MaterialApp(
          home: MandapEditorScreen(
            projectId: 'truss_123456789',
            initialTrussSize: 10.0,
            initialPlotWidth: 100.0,
            initialPlotLength: 100.0,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MandapEditorScreen), findsOneWidget);
    expect(find.byType(InModelDimensionBadge), findsOneWidget);
    expect(find.byType(SimplifiedTrussRail), findsOneWidget);
    expect(find.byType(Mandap3DView), findsOneWidget);

    print('MandapEditorScreen size: ${tester.getSize(find.byType(MandapEditorScreen))}');
    print('TrussRail size: ${tester.getSize(find.byType(SimplifiedTrussRail))}');
    print('DimensionBadge size: ${tester.getSize(find.byType(InModelDimensionBadge))}');
    print('Mandap3DView size: ${tester.getSize(find.byType(Mandap3DView))}');
    print('TrussRail rect: ${tester.getRect(find.byType(SimplifiedTrussRail))}');
    print('DimensionBadge rect: ${tester.getRect(find.byType(InModelDimensionBadge))}');
  });
}
