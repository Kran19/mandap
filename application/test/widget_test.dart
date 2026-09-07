import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_preset.dart';
import 'package:mandap/features/mandap/presentation/mandap_editor_screen.dart';
import 'package:mandap/features/mandap/presentation/widgets/editor_mode_bar.dart';
import 'package:mandap/features/mandap/presentation/widgets/selection_sheet.dart';
import 'package:mandap/main.dart';

void main() {
  group('Responsive UI Verification (No Overflow Allowed)', () {
    void setViewport(WidgetTester tester, double width, double height) {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('Renders cleanly at 360 x 800 (Compact Android Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 360, 800);

      await tester.pumpWidget(const MandapApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(EditorModeBar), findsOneWidget);
      expect(find.byType(PopupMenuButton<MandapPreset>), findsOneWidget);
    });

    testWidgets('Renders cleanly at 390 x 844 (Standard Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 390, 844);

      await tester.pumpWidget(const MandapApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(EditorModeBar), findsOneWidget);
      expect(find.byType(PopupMenuButton<MandapPreset>), findsOneWidget);
    });

    testWidgets('Renders cleanly at 412 x 915 (Large Phone)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 412, 915);

      await tester.pumpWidget(const MandapApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(EditorModeBar), findsOneWidget);
      expect(find.byType(PopupMenuButton<MandapPreset>), findsOneWidget);
    });

    testWidgets('BOM panel expands at 360dp width without overflow', (
      WidgetTester tester,
    ) async {
      setViewport(tester, 360, 800);

      await tester.pumpWidget(const MandapApp());
      await tester.pumpAndSettle();

      // Find drag header text inside BomPanel
      final headerFinder = find.textContaining('TRUSS BOM');
      expect(headerFinder, findsOneWidget);

      // Drag BOM sheet upward to expand
      await tester.drag(headerFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('AGGREGATED TRUSS BOM'), findsOneWidget);
    });
  });

  group('Editor Interaction Smoke Test', () {
    testWidgets(
      'Full UI -> Controller -> Command -> Domain -> Recalculation -> Undo flow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MandapApp());
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

        expect(find.byType(SelectionSheet), findsOneWidget);

        // 3. Perform Move operation (move n1 from (0,0) to (10,0) keeping clean 0.5ft increments)
        controller.moveNode(nodeId: n1Id, newX: 10.0, newZ: 0.0);
        await tester.pumpAndSettle();

        // 4. Verify Geometry Changed
        expect(controller.layout.getNode(n1Id)!.x, 10.0);
        expect(controller.history.canUndo, isTrue);

        // 5. Tap Undo button
        final undoButton = find.widgetWithIcon(IconButton, Icons.undo);
        expect(undoButton, findsOneWidget);
        await tester.tap(undoButton);
        await tester.pumpAndSettle();

        // 6. Verify Geometry Restored
        expect(controller.layout.getNode(n1Id)!.x, 0.0);
        expect(controller.history.canUndo, isFalse);
      },
    );
  });
}
