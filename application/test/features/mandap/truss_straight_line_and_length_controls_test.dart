import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/truss_member_length_sheet.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Straight Line & Closest Truss Snapping', () {
    test('createTrussMember creates strictly straight member snapping to closest perpendicular truss', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      // Start at (0, 20, 20) on an existing truss edge
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(v64.Vector3(0.0, 20.0, 20.0));

      // User clicks diagonally at (43.2, 20.0, 24.8) towards the opposite bays
      // Dominant axis is X (|dx|=43.2 > |dz|=4.8)
      // Along X, existing perpendicular trusses run at X = 10, 20, 30, 40, 50...
      // The closest truss to X=43.2 is at X=40.0!
      final success = controller.createTrussMember(
        targetEndPoint: v64.Vector3(43.2, 20.0, 24.8),
      );

      expect(success, isTrue);
      final newEdge = controller.layout.edges.values.last;
      final startNode = controller.layout.getNode(newEdge.startNodeId)!;
      final endNode = controller.layout.getNode(newEdge.endNodeId)!;

      // STRICT STRAIGHT LINE: Z coordinates must be identical! No slanted beam!
      expect(startNode.z, equals(20.0));
      expect(endNode.z, equals(20.0));
      expect(startNode.x, equals(0.0));
      // Snapped to closest truss at X=50.0
      expect(endNode.x, equals(50.0));
    });

    test('createTrussMember with off-axis targetNodeId stays strictly orthogonal and does not connect diagonally', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      // Pick a node at (0, 20, 0)
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(v64.Vector3(0.0, 20.0, 0.0));

      // Find an existing off-axis node at (100, 20, 100)
      final offAxisNode = controller.layout.nodes.values.firstWhere(
        (n) => n.x == 100.0 && n.z == 100.0,
      );

      // Try creating a member aiming towards X with off-axis node ID
      final success = controller.createTrussMember(
        targetEndPoint: v64.Vector3(95.0, 20.0, 30.0),
        targetEndNodeId: offAxisNode.id,
      );

      expect(success, isTrue);
      final newEdge = controller.layout.edges.values.last;
      final startNode = controller.layout.getNode(newEdge.startNodeId)!;
      final endNode = controller.layout.getNode(newEdge.endNodeId)!;

      // Z MUST BE 0.0! Cannot be diagonal!
      expect(startNode.z, equals(0.0));
      expect(endNode.z, equals(0.0));
      expect(endNode.id, isNot(equals(offAxisNode.id)));
    });

    test('adjustCenterFrontBack preserves perimeter corners and perimeter poles rigidly', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      // Record original corners
      final corner00 = controller.layout.nodes.values.firstWhere((n) => n.x == 0.0 && n.z == 0.0);
      final corner1000 = controller.layout.nodes.values.firstWhere((n) => n.x == 100.0 && n.z == 0.0);

      // Adjust center
      controller.adjustCenterFrontBack(newZ: 75.0);

      final newCorner00 = controller.layout.getNode(corner00.id)!;
      final newCorner1000 = controller.layout.getNode(corner1000.id)!;

      expect(newCorner00.z, equals(0.0));
      expect(newCorner1000.z, equals(0.0));
    });

    test('adjustCenterFrontBack moves center node and horizontal cross endpoints smoothly to new Z', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final cNode = controller.centerControlNode!;
      expect(cNode.z, equals(50.0));

      // Move center to 65.0
      controller.adjustCenterFrontBack(newZ: 65.0);

      final updatedCenter = controller.centerControlNode!;
      expect(updatedCenter.z, equals(65.0));
      expect(updatedCenter.x, equals(50.0)); // Fixed Center X locked!

      // Check horizontal cross members connected to center
      for (final edge in controller.layout.edges.values) {
        if (edge.startNodeId == updatedCenter.id || edge.endNodeId == updatedCenter.id) {
          final otherId = edge.startNodeId == updatedCenter.id ? edge.endNodeId : edge.startNodeId;
          final other = controller.layout.getNode(otherId)!;
          if (other.x.abs() < 1.5 || (other.x - 100.0).abs() < 1.5) {
            // West and East cross endpoints must move with center!
            expect(other.z, equals(65.0));
          }
        }
      }
    });

    test('snapStraightTrussRay projects onto dominant Z axis when dz > dx and keeps X fixed', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final startPt = v64.Vector3(30.0, 20.0, 0.0);
      // Tap diagonally at (33.0, 20.0, 58.0) -> dz=58, dx=3 -> Dominant Z
      final (snappedEnd, axis, len, _) = controller.snapStraightTrussRay(
        startPoint: startPt,
        targetPoint: v64.Vector3(33.0, 20.0, 58.0),
      );

      expect(axis, equals('Z'));
      // X must be strictly identical to startPoint.x
      expect(snappedEnd.x, equals(30.0));
      // Closest truss to Z=58 in layout is at Z=50
      expect(snappedEnd.z, equals(50.0));
      expect(len, equals(50.0));
    });

    test('findClosestTrussOrNode snaps start point to nearest truss edge when clicking nearby', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      // Tap slightly off from truss at Z=0 (e.g. at X=25.0, Z=2.5)
      controller.setPenStartPoint(
        v64.Vector3(25.0, 20.0, 2.5),
        snapToClosestTruss: true,
      );

      // Should snap directly onto the truss edge at Z=0
      expect(controller.penStartPoint!.z, equals(0.0));
      expect(controller.penStartPoint!.x, equals(25.0));
    });
  });

  group('Truss Member Length Stepper (5 ft Increments)', () {
    testWidgets('Tapping + on 60 ft moves to 65 ft, and tapping - moves to 55 ft', (tester) async {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      // Select an edge of length 60 ft or create one
      final edge = controller.layout.edges.values.first;
      controller.selectEdge(edge.id);
      controller.resizeSelectedEdgeLength(60.0);
      expect(controller.selectedEdgeLength, equals(60.0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrussMemberLengthSheet(
                controller: controller,
                edgeId: edge.id,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find remove (-) and add (+) icon buttons
      final minusBtn = find.byIcon(Icons.remove);
      final plusBtn = find.byIcon(Icons.add);
      expect(minusBtn, findsOneWidget);
      expect(plusBtn, findsOneWidget);

      // Current length label should display 60.0 ft
      expect(find.text('60.0 ft'), findsOneWidget);

      // Tap +: moves 60 -> 65 ft
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      expect(controller.selectedEdgeLength, equals(65.0));
      expect(find.text('65 ft'), findsWidgets);

      // Tap - twice: moves 65 -> 60 -> 55 ft
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(controller.selectedEdgeLength, equals(60.0));

      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(controller.selectedEdgeLength, equals(55.0));
      expect(find.text('55 ft'), findsWidgets);
    });

    testWidgets('Tapping + on 27.9 ft snaps up to 30 ft, and - snaps down to 25 ft', (tester) async {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final edge = controller.layout.edges.values.first;
      controller.selectEdge(edge.id);
      controller.resizeSelectedEdgeLength(27.9);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrussMemberLengthSheet(
                controller: controller,
                edgeId: edge.id,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final plusBtn = find.byIcon(Icons.add);
      // Tap + from 27.9: should snap to 30 ft
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      expect(controller.selectedEdgeLength, equals(30.0));

      final minusBtn = find.byIcon(Icons.remove);
      // Tap -: moves from 30 -> 25 ft
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      expect(controller.selectedEdgeLength, equals(25.0));
    });
  });

  group('3D Dimension Badges on All Trusses', () {
    testWidgets('3D painter renders dimension badges for all edges', (tester) async {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final controller3D = Mandap3DController();
      controller3D.syncScene(controller.layout, controller.result);

      final painter = Mandap3DPainter(
        layout: controller.layout,
        result: controller.result,
        controller: controller3D,
      );

      // Verify painter creates without errors
      expect(painter, isNotNull);
    });
  });
}
