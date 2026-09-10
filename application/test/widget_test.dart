import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/features/mandap/presentation/mandap_editor_screen.dart';
import 'package:mandap/features/mandap/presentation/editor/widgets/cad_header_bar.dart';
import 'package:mandap/features/mandap/presentation/editor/widgets/tool_rail_widget.dart';
import 'package:mandap/features/mandap/presentation/editor/widgets/inspector_bom_panel.dart';
import 'package:mandap/features/auth/application/bootstrap_coordinator.dart';
import 'package:mandap/features/auth/domain/models/auth_state.dart';
import 'package:mandap/features/auth/domain/models/auth_user.dart';

class MockBootstrapCoordinator extends Mock implements BootstrapCoordinator {}

Widget createEditorTestSurface({String projectId = 'new'}) {
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

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BootstrapCoordinator>.value(value: mockCoordinator),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MandapEditorScreen(projectId: projectId),
    ),
  );
}

void main() {
  group('CAD Shell Responsive UI Verification (No Overflow Allowed)', () {
    void setViewport(WidgetTester tester, double width, double height) {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('Renders cleanly at 360 x 800 (Compact Android Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 360, 800);

      await tester.pumpWidget(createEditorTestSurface());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CadHeaderBar), findsOneWidget);
      expect(find.byType(ToolRailWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 390 x 844 (Standard Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 390, 844);

      await tester.pumpWidget(createEditorTestSurface());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CadHeaderBar), findsOneWidget);
      expect(find.byType(ToolRailWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 412 x 915 (Large Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 412, 915);

      await tester.pumpWidget(createEditorTestSurface());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CadHeaderBar), findsOneWidget);
      expect(find.byType(ToolRailWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders CAD Desktop view cleanly at 1024 x 768 with docked Inspector', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 1024, 768);

      await tester.pumpWidget(createEditorTestSurface());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CadHeaderBar), findsOneWidget);
      expect(find.byType(ToolRailWidget), findsOneWidget);
      expect(find.byType(InspectorBomPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Editor Interaction Smoke Test', () {
    testWidgets(
      'Full UI -> Controller -> Command -> Domain -> Recalculation -> Undo flow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createEditorTestSurface());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        final state = tester.state<MandapEditorScreenState>(
          find.byType(MandapEditorScreen),
        );
        final controller = state.controller;

        // 1. Initial State: 40x30 Rectangle (n1 at 0,0; n2 at 40,0)
        expect(controller.currentPreset.id, 'rect_40x30');
        expect(
          controller.layout.getNode(controller.layout.nodes.keys.first)!.x,
          0.0,
        );
        expect(controller.history.canUndo, isFalse);

        // 2. Select n1 node
        final n1Id = controller.layout.nodes.keys.first;
        controller.selectNode(n1Id);
        await tester.pumpAndSettle();

        expect(controller.selectedNodeId, n1Id);
        expect(find.byType(InspectorBomPanel), findsOneWidget);

        // 3. Perform Move operation (move n1 from (0,0) to (10,0) keeping clean 0.5ft increments)
        controller.moveNode(nodeId: n1Id, newX: 10.0, newZ: 0.0);
        await tester.pumpAndSettle();

        // 4. Verify Geometry Changed
        expect(controller.layout.getNode(n1Id)!.x, 10.0);
        expect(controller.history.canUndo, isTrue);

        // 5. Tap Undo button in ToolRailWidget
        final undoButton = find.widgetWithIcon(IconButton, Icons.undo);
        expect(undoButton, findsOneWidget);
        await tester.tap(undoButton);
        await tester.pumpAndSettle();

        // 6. Verify Geometry Restored
        expect(controller.layout.getNode(n1Id)!.x, 0.0);
        expect(controller.history.canUndo, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
