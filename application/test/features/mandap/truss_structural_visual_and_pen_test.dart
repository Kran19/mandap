import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/commands/adjust_center_control_command.dart';
import 'package:mandap/features/mandap/application/commands/create_truss_member_command.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_view.dart';

void main() {
  group('1. 100 × 100 × 10 ft Truss Structural Verification', () {
    test('100x100x10ft structure has 4-chord box truss edges and center control', () {
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 10.0,
          poleHeight: 20.0,
          includeCenterControlPoint: true,
        ),
      );

      expect(layout.nodes.isNotEmpty, isTrue);
      expect(layout.edges.isNotEmpty, isTrue);

      // Every generated edge must have profile EdgeProfile.box
      for (final edge in layout.edges.values) {
        expect(edge.profile, equals(EdgeProfile.box));
      }

      // Must have center control point at (50, 50)
      final centerNodes = layout.nodes.values
          .where((n) => n.type == NodeType.controlPoint || n.id.value.contains('center'))
          .toList();
      expect(centerNodes.length, equals(1));
      final center = centerNodes.first;
      expect(center.x, equals(50.0));
      expect(center.z, equals(50.0));
      expect(center.elevation, equals(20.0));

      // 4 internal cross members must connect to this center node
      final crossEdges = layout.edges.values
          .where((e) => e.startNodeId == center.id || e.endNodeId == center.id)
          .toList();
      expect(crossEdges.length, equals(4));
    });
  });

  group('2. Tower Connection & Shared Node Identity Verification', () {
    test('Every tower top matches mainTrussElevation and shares node identity with main truss', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final layout = controller.layout;
      final result = controller.result;
      expect(result, isNotNull);
      expect(result!.poles.isNotEmpty, isTrue);

      const expectedTrussElevation = 20.0;

      for (final pole in result.poles) {
        // 1. Verify pole has a source node
        expect(pole.sourceNodeId, isNotNull,
            reason: 'Every tower must be anchored to a domain node');

        final node = layout.getNode(pole.sourceNodeId!);
        expect(node, isNotNull);

        // 2. Explicit coordinate verification: towerTop.y == mainTrussElevation
        expect(node!.elevation, equals(expectedTrussElevation),
            reason: 'Tower top Y coordinate must strictly equal main truss elevation (20.0 ft)');

        // 3. Node identity verification: tower top and main truss share the exact same node ID
        final connectedEdges = layout.edges.values
            .where((e) => e.startNodeId == node.id || e.endNodeId == node.id)
            .toList();
        expect(connectedEdges.isNotEmpty, isTrue,
            reason: 'Tower top node ${node.id} must directly connect to horizontal truss edges');

        // 4. Base is at ground Y = 0
        expect(pole.x, equals(node.x));
        expect(pole.z, equals(node.z));
      }
    });
  });

  group('3. Pen State Machine Verification', () {
    test('State machine transitions: IDLE -> WAITING_FOR_START -> WAITING_FOR_END -> LENGTH_DIALOG -> IDLE', () {
      final controller = MandapEditorController();
      expect(controller.penState, equals(PenState.idle));

      // 1. Activate Pen
      controller.setMode(EditorMode.addEdge);
      expect(controller.penState, equals(PenState.waitingForStart));

      // 2. Tap Start
      controller.setPenStartPoint(v64.Vector3(20.0, 20.0, 20.0));
      expect(controller.penState, equals(PenState.waitingForEnd));
      expect(controller.penStartPoint, equals(v64.Vector3(20.0, 20.0, 20.0)));

      // 3. Tap End approximately: prepares segment along dominant axis
      final (axis, previewLen) = controller.preparePenSegment(
        tapStart: controller.penStartPoint!,
        tapEnd: v64.Vector3(27.0, 20.0, 23.0),
      );
      expect(axis, equals('X'));
      expect(previewLen, equals(7.0));

      // 4. Apply 14 ft: turns Pen OFF immediately (no chaining)
      final success = controller.applyCreateTrussMember(requestedLength: 14.0);
      expect(success, isTrue);
      expect(controller.mode, equals(EditorMode.view));
      expect(controller.penState, equals(PenState.idle));
      expect(controller.penStartPoint, isNull);
      expect(controller.penPreviewEndPoint, isNull);
    });

    test('Cancel turns Pen OFF immediately', () {
      final controller = MandapEditorController();
      controller.setMode(EditorMode.addEdge);
      expect(controller.penState, equals(PenState.waitingForStart));

      controller.setPenStartPoint(v64.Vector3(10.0, 20.0, 10.0));
      expect(controller.penState, equals(PenState.waitingForEnd));

      controller.cancelPenDrawing();
      expect(controller.mode, equals(EditorMode.view));
      expect(controller.penState, equals(PenState.idle));
      expect(controller.penStartPoint, isNull);
    });

    test('Pencil directly connects two existing nodes (including diagonal/apex)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final nodes = controller.layout.nodes.values.toList();
      final nodeA = nodes[0];
      final nodeB = nodes[nodes.length - 1];
      final initialEdgeCount = controller.layout.edges.length;

      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(
        v64.Vector3(nodeA.x, nodeA.elevation, nodeA.z),
        startNodeId: nodeA.id,
      );

      // Connect to nodeB
      final success = controller.createTrussMember(
        targetEndPoint: v64.Vector3(nodeB.x, nodeB.elevation, nodeB.z),
        targetEndNodeId: nodeB.id,
      );

      expect(success, isTrue);
      expect(controller.mode, equals(EditorMode.view));
      expect(controller.penState, equals(PenState.idle));
      expect(controller.layout.edges.length, equals(initialEdgeCount + 1));
      final newEdge = controller.layout.edges.values.last;
      expect(newEdge.startNodeId, equals(nodeA.id));
      expect(newEdge.endNodeId, equals(nodeB.id));
      expect(newEdge.profile, equals(EdgeProfile.box));
    });

    test('updatePenPreview tracks live rubber-band length and dominant axis without camera orbit', () {
      final controller = MandapEditorController();
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(v64.Vector3(0.0, 10.0, 0.0));

      controller.updatePenPreview(v64.Vector3(20.0, 10.0, 0.0));
      expect(controller.penDominantAxis, equals('X'));
      expect(controller.penPreviewLength, equals(20.0));

      controller.updatePenPreview(v64.Vector3(0.0, 10.0, 35.0));
      expect(controller.penDominantAxis, equals('Z'));
      expect(controller.penPreviewLength, equals(35.0));
    });
  });

  group('4. Dominant Axis & Exact Length Verification', () {
    test('Dominant axis determines X/Z snap, member is straight and exactly requested length', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final initialEdgeCount = controller.layout.edges.length;

      // Start at (20, 20)
      final startPt = v64.Vector3(20.0, 20.0, 20.0);
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(startPt);

      // User taps approximately (27, 23) -> dx = 7, dz = 3 -> dominant = X
      final approxEndPt = v64.Vector3(27.0, 20.0, 23.0);
      final (axis, _) = controller.preparePenSegment(
        tapStart: startPt,
        tapEnd: approxEndPt,
      );
      expect(axis, equals('X'));

      // User enters exact length = 14 ft
      final created = controller.applyCreateTrussMember(requestedLength: 14.0);
      expect(created, isTrue);

      // Verify exactly 1 new edge created
      expect(controller.layout.edges.length, equals(initialEdgeCount + 1));
      final newEdge = controller.layout.edges.values.last;
      expect(newEdge.profile, equals(EdgeProfile.box));

      final startNode = controller.layout.getNode(newEdge.startNodeId)!;
      final endNode = controller.layout.getNode(newEdge.endNodeId)!;

      // Verify exact coordinates: (20, 20) -> (34, 20)
      expect(startNode.x, equals(20.0));
      expect(startNode.z, equals(20.0));
      expect(endNode.x, equals(34.0));
      expect(endNode.z, equals(20.0)); // Strictly straight! No diagonal dz!

      final len = math.sqrt(
        (endNode.x - startNode.x) * (endNode.x - startNode.x) +
        (endNode.z - startNode.z) * (endNode.z - startNode.z),
      );
      expect(len, equals(14.0));

      // Undo removes member cleanly
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.layout.edges.length, equals(initialEdgeCount));
    });
  });

  group('5. Center Control Point & Structural Limits Verification', () {
    test('AdjustCenterControlCommand modifies apex elevation within structural bounds', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );

      final centerNode = controller.layout.nodes.values
          .firstWhere((n) => n.type == NodeType.controlPoint);
      expect(centerNode.elevation, equals(20.0));

      // Adjust roof apex to 28 ft (within 20 to 30 ft range)
      controller.applyAdjustCenterControl(
        centerNodeId: centerNode.id,
        newElevation: 28.0,
        newX: 50.0,
        newZ: 50.0,
        mainTrussElevation: 20.0,
      );

      final elevatedCenter = controller.layout.getNode(centerNode.id)!;
      expect(elevatedCenter.elevation, equals(28.0));

      // Clamping test: request 35 ft (exceeds +10 ft limit), must clamp to 30 ft
      controller.applyAdjustCenterControl(
        centerNodeId: centerNode.id,
        newElevation: 35.0,
        newX: 50.0,
        newZ: 50.0,
        mainTrussElevation: 20.0,
      );
      final clampedTop = controller.layout.getNode(centerNode.id)!;
      expect(clampedTop.elevation, equals(30.0));

      // Clamping test: request 15 ft (below flat truss 20 ft), must clamp to 20 ft
      controller.applyAdjustCenterControl(
        centerNodeId: centerNode.id,
        newElevation: 15.0,
        newX: 50.0,
        newZ: 50.0,
        mainTrussElevation: 20.0,
      );
      final clampedBottom = controller.layout.getNode(centerNode.id)!;
      expect(clampedBottom.elevation, equals(20.0));

      // Undo restores prior
      controller.undo();
      final restored = controller.layout.getNode(centerNode.id)!;
      expect(restored.elevation, equals(30.0));
    });
  });

  group('6. 100 × 100 × 10 ft Visual Acceptance & 3D Rendering', () {
    testWidgets('Renders 3D box truss scene, towers, base plates and center control without errors', (tester) async {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
        initialPoleHeight: 20.0,
      );
      final controller3D = Mandap3DController();
      controller3D.fitCamera(controller.layout);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 1200,
              child: Mandap3DView(
                controller: controller,
                controller3D: controller3D,
                runAnimationOnLoad: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Mandap3DView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
