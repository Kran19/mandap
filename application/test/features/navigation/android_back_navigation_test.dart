import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/core/localization/locale_notifier.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';
import 'package:mandap/features/module_selection/presentation/module_selection_screen.dart';
import 'package:mandap/features/mandap/presentation/mandap_editor_screen.dart';
import 'package:mandap/features/mandap/presentation/wizard/create_truss_dialog.dart';
import 'package:mandap/features/pole/presentation/pole_calculator_screen.dart';
import 'package:mandap/features/pole/presentation/widgets/create_pole_dialog.dart';
import 'package:mandap/features/stage/presentation/stage_calculator_screen.dart';
import 'package:mandap/features/stage/presentation/widgets/create_stage_dialog.dart';
import 'package:mandap/features/flooring/presentation/flooring_calculator_screen.dart';
import 'package:mandap/features/flooring/presentation/widgets/create_flooring_dialog.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';

class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}
class MockLocaleNotifier extends Mock implements LocaleNotifier {}

Widget createNavigationTestApp({
  required GoRouter router,
  MockBootstrapCoordinator? coordinator,
  MockLocaleNotifier? localeNotifier,
}) {
  final mockCoord = coordinator ?? MockBootstrapCoordinator();
  when(() => mockCoord.logout()).thenAnswer((_) async {});
  when(() => mockCoord.current).thenReturn(
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

  final mockLoc = localeNotifier ?? MockLocaleNotifier();
  when(() => mockLoc.locale).thenReturn(const Locale('en'));
  when(() => mockLoc.currentLanguage).thenReturn(kApprovedLanguages[0]);

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

GoRouter createTestRouter({String initialLocation = '/modules'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/modules',
        builder: (context, state) => const ModuleSelectionScreen(),
        onExit: (context) async {
          final l10n = AppLocalizations.of(context);
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                l10n?.exitApp ?? 'Exit MANDAP?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                l10n?.confirmExit ?? 'Are you sure you want to exit the application?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n?.exit ?? 'Exit'),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        },
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'] ?? 'new';
          return MandapEditorScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/pole',
        builder: (context, state) => const PoleCalculatorScreen(),
      ),
      GoRoute(
        path: '/stage',
        builder: (context, state) => const StageCalculatorScreen(),
      ),
      GoRoute(
        path: '/flooring',
        builder: (context, state) => const FlooringCalculatorScreen(),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MANDAP Android Back Button & Navigation — 16 Requirements Verification', () {
    // -------------------------------------------------------------------------
    // Requirement 1: Editor Back → /modules
    // -------------------------------------------------------------------------
    testWidgets('1. Editor Back navigates to /modules without exiting app', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      expect(find.byType(MandapEditorScreen), findsOneWidget);

      // Simulate Android physical/system Back button
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue); // Intercepted by PopScope
      await tester.pumpAndSettle();

      // Verify returned to /modules
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(find.byType(MandapEditorScreen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 2: Pole Back → /modules
    // -------------------------------------------------------------------------
    testWidgets('2. Pole Back navigates to /modules without exiting app', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/pole');
      await tester.pumpAndSettle();

      expect(find.byType(PoleCalculatorScreen), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(find.byType(PoleCalculatorScreen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 3: Stage Back → /modules
    // -------------------------------------------------------------------------
    testWidgets('3. Stage Back navigates to /modules without exiting app', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/stage');
      await tester.pumpAndSettle();

      expect(find.byType(StageCalculatorScreen), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(find.byType(StageCalculatorScreen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 4: Flooring Back → /modules
    // -------------------------------------------------------------------------
    testWidgets('4. Flooring Back navigates to /modules without exiting app', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/flooring');
      await tester.pumpAndSettle();

      expect(find.byType(FlooringCalculatorScreen), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(find.byType(FlooringCalculatorScreen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 5: Create Truss dialog Back closes dialog and stays on /modules
    // -------------------------------------------------------------------------
    testWidgets('5. Create Truss dialog Back closes dialog and leaves /modules visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap TRUSS card to open CreateTrussDialog
      await tester.tap(find.text('TRUSS'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTrussDialog), findsOneWidget);

      // Press Android Back
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // Dialog is closed; user remains on /modules; did not navigate to /editor
      expect(find.byType(CreateTrussDialog), findsNothing);
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(find.byType(MandapEditorScreen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 6: Create Pole dialog Back closes dialog and stays on /modules
    // -------------------------------------------------------------------------
    testWidgets('6. Create Pole dialog Back closes dialog and leaves /modules visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('PIPE'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePoleDialog), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(CreatePoleDialog), findsNothing);
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 7: Create Stage dialog Back closes dialog and stays on /modules
    // -------------------------------------------------------------------------
    testWidgets('7. Create Stage dialog Back closes dialog and leaves /modules visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('STAGE'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateStageDialog), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(CreateStageDialog), findsNothing);
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 8: Create Flooring dialog Back closes dialog and stays on /modules
    // -------------------------------------------------------------------------
    testWidgets('8. Create Flooring dialog Back closes dialog and leaves /modules visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('FLOORING'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateFlooringDialog), findsOneWidget);

      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(CreateFlooringDialog), findsNothing);
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/modules');
    });

    // -------------------------------------------------------------------------
    // Requirement 9: Back does not call SystemNavigator.pop
    // -------------------------------------------------------------------------
    testWidgets('9. Back from module routes never calls SystemNavigator.pop', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var systemPopCalled = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalled = true;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      for (final path in ['/editor', '/pole', '/stage', '/flooring']) {
        systemPopCalled = false;
        final router = createTestRouter(initialLocation: '/modules');
        await tester.pumpWidget(createNavigationTestApp(router: router));
        await tester.pump();
        await tester.pumpAndSettle();

        router.push(path);
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(systemPopCalled, isFalse, reason: 'SystemNavigator.pop called on Back from $path');
        expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      }
    });

    // -------------------------------------------------------------------------
    // Requirement 10: Back does not mutate MandapLayout
    // -------------------------------------------------------------------------
    testWidgets('10. Back navigation does not mutate MandapLayout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      final initialLayout = state.controller.layout;
      final initialNodeCount = initialLayout.nodes.length;
      final initialEdgeCount = initialLayout.edges.length;

      // Trigger Back
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(state.controller.layout.nodes.length, initialNodeCount);
      expect(state.controller.layout.edges.length, initialEdgeCount);
      expect(state.controller.layout, equals(initialLayout));
    });

    // -------------------------------------------------------------------------
    // Requirement 11: Back does not mutate MandapNode
    // -------------------------------------------------------------------------
    testWidgets('11. Back navigation does not mutate MandapNode coordinates or properties', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      final nodesBefore = state.controller.layout.nodes.values.map((n) => (id: n.id, x: n.x, z: n.z, type: n.type)).toList();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final nodesAfter = state.controller.layout.nodes.values.map((n) => (id: n.id, x: n.x, z: n.z, type: n.type)).toList();
      expect(nodesAfter, equals(nodesBefore));
    });

    // -------------------------------------------------------------------------
    // Requirement 12: Back does not mutate MandapEdge
    // -------------------------------------------------------------------------
    testWidgets('12. Back navigation does not mutate MandapEdge connectivity or count', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      final edgesBefore = state.controller.layout.edges.values.map((e) => (id: e.id, start: e.startNodeId, end: e.endNodeId)).toList();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final edgesAfter = state.controller.layout.edges.values.map((e) => (id: e.id, start: e.startNodeId, end: e.endNodeId)).toList();
      expect(edgesAfter, equals(edgesBefore));
    });

    // -------------------------------------------------------------------------
    // Requirement 13: Back does not change BOM
    // -------------------------------------------------------------------------
    testWidgets('13. Back navigation does not change BOM calculations', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      final polesBefore = state.controller.totalPoleCount;
      final piecesBefore = state.controller.totalPiecesRequired;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(state.controller.totalPoleCount, equals(polesBefore));
      expect(state.controller.totalPiecesRequired, equals(piecesBefore));
    });

    // -------------------------------------------------------------------------
    // Requirement 14: Pen state (ON/OFF) does not affect Back
    // -------------------------------------------------------------------------
    testWidgets('14. Pen state (ON/OFF) does not affect Back or mutate geometry', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      
      // Activate PEN mode
      state.controller.setMode(EditorMode.addEdge);
      expect(state.controller.mode, EditorMode.addEdge);

      final nodeCountBefore = state.controller.layout.nodes.length;
      final edgeCountBefore = state.controller.layout.edges.length;

      // Press Back with PEN ON
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // Successfully navigated to /modules
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(state.controller.layout.nodes.length, nodeCountBefore);
      expect(state.controller.layout.edges.length, edgeCountBefore);
    });

    // -------------------------------------------------------------------------
    // Requirement 15: Eraser state (ON/OFF) does not affect Back
    // -------------------------------------------------------------------------
    testWidgets('15. Eraser state (ON/OFF) does not affect Back or mutate geometry', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));

      // Activate ERASER mode
      state.controller.setMode(EditorMode.delete);
      expect(state.controller.mode, EditorMode.delete);

      final nodeCountBefore = state.controller.layout.nodes.length;
      final edgeCountBefore = state.controller.layout.edges.length;

      // Press Back with ERASER ON
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // Successfully navigated to /modules without deleting anything
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
      expect(state.controller.layout.nodes.length, nodeCountBefore);
      expect(state.controller.layout.edges.length, edgeCountBefore);
    });

    // -------------------------------------------------------------------------
    // Requirement 16: 2D & 3D editor Back works cleanly (including camera orbit/pan/zoom)
    // -------------------------------------------------------------------------
    testWidgets('16. 2D and 3D editor Back works with camera transformations', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Sub-test A: 2D View Back
      var router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      // Switch to 2D
      await tester.tap(find.text('2D'));
      await tester.pumpAndSettle();

      var didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);

      // Sub-test B: 3D View with camera transformations
      router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      final state = tester.state<MandapEditorScreenState>(find.byType(MandapEditorScreen));
      // Switch to 3D and transform camera
      await tester.tap(find.text('3D'));
      await tester.pumpAndSettle();

      state.controller3D.orbitCamera(25.0, 15.0);
      state.controller3D.panCamera(20.0, 10.0);
      state.controller3D.zoomCamera(1.5);

      didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Additional Test: Double Back Behavior
    // -------------------------------------------------------------------------
    testWidgets('Double Back: first Back returns to /modules, second Back shows exit confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createTestRouter(initialLocation: '/modules');
      await tester.pumpWidget(createNavigationTestApp(router: router));
      await tester.pump();
      await tester.pumpAndSettle();

      router.push('/editor');
      await tester.pumpAndSettle();

      // First Back: from /editor to /modules
      var didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);

      // Second Back: on /modules, triggers exit confirmation dialog
      final popFuture = tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // "Exit MANDAP?" dialog appears
      expect(find.text('Exit MANDAP?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      // Cancel keeps user on /modules
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final didPop2 = await popFuture;
      expect(didPop2, isTrue);

      expect(find.text('Exit MANDAP?'), findsNothing);
      expect(find.byType(ModuleSelectionScreen), findsOneWidget);
    });
  });
}
