import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/core/localization/locale_notifier.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';
import 'package:mandap/features/module_selection/presentation/module_selection_screen.dart';

class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}
class MockLocaleNotifier extends Mock implements LocaleNotifier {}

Widget createModuleSelectionTestSurface() {
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

  final mockLocaleNotifier = MockLocaleNotifier();
  when(() => mockLocaleNotifier.locale).thenReturn(const Locale('en'));
  when(() => mockLocaleNotifier.currentLanguage).thenReturn(kApprovedLanguages[0]);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoordinator),
      ChangeNotifierProvider<LocaleNotifier>.value(value: mockLocaleNotifier),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ModuleSelectionScreen(),
    ),
  );
}

void main() {
  group('ModuleSelectionScreen Background & Responsive UI Verification', () {
    testWidgets('Renders background image and all 4 module cards without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createModuleSelectionTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify background.png is present in the tree
      final bgImageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/images/background.png',
      );
      expect(bgImageFinder, findsOneWidget);

      // Verify Title & Subtitle
      expect(find.text('Choose what to design'), findsOneWidget);

      // Verify all 4 module cards
      expect(find.text('TRUSS'), findsOneWidget);
      expect(find.text('PIPE'), findsOneWidget);
      expect(find.text('STAGE'), findsOneWidget);
      expect(find.text('FLOORING'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on compact mobile (360 x 800) with background', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createModuleSelectionTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on tablet/desktop (1024 x 768) with background', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createModuleSelectionTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
