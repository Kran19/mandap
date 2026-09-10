import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:mandap/features/auth/presentation/login_screen.dart';
import 'package:mandap/features/auth/infrastructure/auth_repository.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockBootstrapCoordinator mockCoordinator;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockCoordinator = MockBootstrapCoordinator();
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: mockAuthRepository),
        ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoordinator),
      ],
      child: MaterialApp(
        home: Scaffold(body: const LoginScreen()),
      ),
    );
  }

  testWidgets('renders login form properly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Phone and Password
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shows error message when login fails', (WidgetTester tester) async {
    when(() => mockAuthRepository.login(any(), any())).thenAnswer((_) async => LoginResult.error('Invalid phone or password'));

    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Continue'));
    
    // Initial pump for setState, another for Future completion
    await tester.pump();
    await tester.pump();

    expect(find.text('Invalid phone or password'), findsOneWidget);
    verify(() => mockAuthRepository.login('9876543210', 'password')).called(1);
    verifyNever(() => mockCoordinator.bootstrap());
  });

  testWidgets('triggers bootstrap when login succeeds', (WidgetTester tester) async {
    when(() => mockAuthRepository.login(any(), any())).thenAnswer((_) async => LoginResult.authenticated());
    when(() => mockCoordinator.bootstrap()).thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Continue'));
    
    await tester.pump();
    await tester.pump();

    expect(find.text('Invalid phone or password'), findsNothing);
    verify(() => mockAuthRepository.login('9876543210', 'password')).called(1);
    verify(() => mockCoordinator.bootstrap()).called(1);
  });
}
