import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/core/localization/locale_notifier.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';
import 'package:mandap/features/projects/infrastructure/local_project_store.dart';
import 'package:mandap/features/projects/presentation/widgets/my_projects_section.dart';
import 'package:mandap/features/module_selection/presentation/module_selection_screen.dart';

class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}
class MockLocaleNotifier extends Mock implements LocaleNotifier {}

Widget createTestApp({
  required Widget child,
  GoRouter? router,
}) {
  final mockCoord = MockBootstrapCoordinator();
  when(() => mockCoord.logout()).thenAnswer((_) async {});
  when(() => mockCoord.current).thenReturn(
    const BootstrapResult(
      authState: AppAuthState.authenticated,
      onboardingState: OnboardingState.complete,
      destination: AppDestination.projects,
      user: AuthUser(
        id: 'usr_test',
        email: 'test@example.com',
        firstName: 'Designer',
        lastName: 'One',
        emailVerified: true,
        mobileVerified: true,
        identityVerified: true,
        organizationId: 'org_test',
      ),
    ),
  );

  final mockLoc = MockLocaleNotifier();
  when(() => mockLoc.locale).thenReturn(const Locale('en'));
  when(() => mockLoc.currentLanguage).thenReturn(kApprovedLanguages[0]);

  if (router != null) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoord),
        ChangeNotifierProvider<LocaleNotifier>.value(value: mockLoc),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoord),
      ChangeNotifierProvider<LocaleNotifier>.value(value: mockLoc),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MANDAP My Projects Section & Module Filter Tests', () {
    testWidgets('1. Empty state renders when no projects exist', (tester) async {
      await tester.pumpWidget(createTestApp(child: const MyProjectsSection()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('All Projects'), findsOneWidget);
      expect(find.text('Truss'), findsOneWidget);
      expect(find.text('Pipe'), findsOneWidget);
      expect(find.text('Stage'), findsOneWidget);
      expect(find.text('Flooring'), findsOneWidget);
      expect(find.text('No projects created yet'), findsOneWidget);
    });

    testWidgets('2. Saves and loads projects across all 4 modules', (tester) async {
      final store = LocalProjectStore();
      final now = DateTime.now();

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'truss_1',
          title: 'Royal Mandap Truss 120 × 80 ft',
          moduleType: 'truss',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 120.0, 'length': 80.0, 'trussSize': 10.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'pole_1',
          title: 'Poles Grid 100 × 100 ft',
          moduleType: 'pole',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 100.0, 'length': 100.0, 'pipeSize': 15.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'stage_1',
          title: 'Concert Stage 40 × 30 ft',
          moduleType: 'stage',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 40.0, 'length': 30.0, 'tableLength': 4.0, 'tableWidth': 8.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'flooring_1',
          title: 'Dining Flooring 60 × 60 ft',
          moduleType: 'flooring',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 60.0, 'length': 60.0, 'carpetLength': 4.0, 'carpetWidth': 4.0},
        ),
      );

      final all = await store.getAllSavedProjects();
      expect(all.length, 4);
    });

    testWidgets('3. Module filtering displays correct projects for each filter tab', (tester) async {
      final store = LocalProjectStore();
      final now = DateTime.now();

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'truss_1',
          title: 'Royal Mandap Truss',
          moduleType: 'truss',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 120.0, 'length': 80.0, 'trussSize': 10.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'pole_1',
          title: 'Grand Hall Poles',
          moduleType: 'pole',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 100.0, 'length': 100.0, 'pipeSize': 15.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'stage_1',
          title: 'VIP Stage Setup',
          moduleType: 'stage',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 40.0, 'length': 30.0, 'tableLength': 4.0, 'tableWidth': 8.0},
        ),
      );

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'flooring_1',
          title: 'Red Carpet Flooring',
          moduleType: 'flooring',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 60.0, 'length': 60.0, 'carpetLength': 4.0, 'carpetWidth': 4.0},
        ),
      );

      await tester.pumpWidget(createTestApp(child: const MyProjectsSection()));
      await tester.pump();
      await tester.pumpAndSettle();

      // All Projects: All 4 should be visible
      expect(find.text('Royal Mandap Truss'), findsOneWidget);
      expect(find.text('Grand Hall Poles'), findsOneWidget);
      expect(find.text('VIP Stage Setup'), findsOneWidget);
      expect(find.text('Red Carpet Flooring'), findsOneWidget);

      // Filter: Truss
      await tester.tap(find.text('Truss'));
      await tester.pumpAndSettle();
      expect(find.text('Royal Mandap Truss'), findsOneWidget);
      expect(find.text('Grand Hall Poles'), findsNothing);
      expect(find.text('VIP Stage Setup'), findsNothing);
      expect(find.text('Red Carpet Flooring'), findsNothing);

      // Filter: Pipe
      await tester.tap(find.text('Pipe'));
      await tester.pumpAndSettle();
      expect(find.text('Royal Mandap Truss'), findsNothing);
      expect(find.text('Grand Hall Poles'), findsOneWidget);
      expect(find.text('VIP Stage Setup'), findsNothing);
      expect(find.text('Red Carpet Flooring'), findsNothing);

      // Filter: Stage
      await tester.tap(find.text('Stage'));
      await tester.pumpAndSettle();
      expect(find.text('Royal Mandap Truss'), findsNothing);
      expect(find.text('Grand Hall Poles'), findsNothing);
      expect(find.text('VIP Stage Setup'), findsOneWidget);
      expect(find.text('Red Carpet Flooring'), findsNothing);

      // Filter: Flooring
      await tester.tap(find.text('Flooring'));
      await tester.pumpAndSettle();
      expect(find.text('Royal Mandap Truss'), findsNothing);
      expect(find.text('Grand Hall Poles'), findsNothing);
      expect(find.text('VIP Stage Setup'), findsNothing);
      expect(find.text('Red Carpet Flooring'), findsOneWidget);

      // Switch back to All Projects
      await tester.tap(find.text('All Projects'));
      await tester.pumpAndSettle();
      expect(find.text('Royal Mandap Truss'), findsOneWidget);
      expect(find.text('Grand Hall Poles'), findsOneWidget);
      expect(find.text('VIP Stage Setup'), findsOneWidget);
      expect(find.text('Red Carpet Flooring'), findsOneWidget);
    });

    testWidgets('4. Deleting a project removes it from store and UI', (tester) async {
      final store = LocalProjectStore();
      final now = DateTime.now();

      await store.saveProjectRecord(
        MandapSavedProject(
          id: 'truss_to_delete',
          title: 'Project To Delete',
          moduleType: 'truss',
          createdAt: now,
          updatedAt: now,
          parameters: {'width': 50.0, 'length': 50.0, 'trussSize': 10.0},
        ),
      );

      await tester.pumpWidget(createTestApp(child: const MyProjectsSection()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Project To Delete'), findsOneWidget);

      // Tap delete icon button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Delete Project?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Project To Delete'), findsNothing);
      final remaining = await store.getAllSavedProjects();
      expect(remaining.isEmpty, isTrue);
    });

    testWidgets('5. ModuleSelectionScreen switches between Design Modules and My Projects tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/modules',
        routes: [
          GoRoute(
            path: '/modules',
            builder: (context, state) => const ModuleSelectionScreen(),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(child: const SizedBox.shrink(), router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      // Starts on Design Modules tab
      expect(find.text('Choose what to design'), findsOneWidget);
      expect(find.text('TRUSS'), findsOneWidget);
      expect(find.text('PIPE'), findsOneWidget);
      expect(find.text('STAGE'), findsOneWidget);
      expect(find.text('FLOORING'), findsOneWidget);

      // Tap 'My Projects' tab in segmented switcher
      await tester.tap(find.text('My Projects'));
      await tester.pumpAndSettle();

      // Now on My Projects tab
      expect(find.byType(MyProjectsSection), findsOneWidget);
      expect(find.text('All Projects'), findsOneWidget);
      expect(find.text('Truss'), findsOneWidget);
      expect(find.text('Pipe'), findsOneWidget);

      // Tap back to 'Design Modules'
      await tester.tap(find.text('Design Modules'));
      await tester.pumpAndSettle();

      expect(find.text('Choose what to design'), findsOneWidget);
      expect(find.text('TRUSS'), findsOneWidget);
    });
  });
}
