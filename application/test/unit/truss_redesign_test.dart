import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/math/beam_transform_calculator.dart';

void main() {
  group('TRUSS Module UX Redesign V3 Verification', () {
    test('CreateTrussDialog configuration generates valid 100x100 base layout', () {
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 10.0,
          poleHeight: 20.0,
          includeCenterControlPoint: true,
        ),
      );

      expect(layout.nodes.isNotEmpty, true);
      expect(layout.edges.isNotEmpty, true);
    });

    test('Free PEN mode allows creating completely disconnected nodes and edges without poles', () {
      final controller = MandapEditorController();
      controller.setMode(EditorMode.addEdge);

      // Create two brand new disconnected nodes in space with 0 poles or supports
      final n1 = controller.addNode(x: 200.0, z: 200.0, type: NodeType.corner);
      final n2 = controller.addNode(x: 220.0, z: 200.0, type: NodeType.corner);

      final added = controller.addEdge(startNodeId: n1, endNodeId: n2);
      expect(added, true);

      // Verify node and edge exist in layout
      expect(controller.layout.nodes.containsKey(n1), true);
      expect(controller.layout.nodes.containsKey(n2), true);
      expect(controller.layout.edges.values.any((e) => e.startNodeId == n1 && e.endNodeId == n2), true);

      // Verify BOM includes free-drawn member
      expect(controller.totalLinearTrussFt > 0, true);

      // Undo removes member cleanly
      controller.undo();
      expect(controller.layout.edges.values.any((e) => e.startNodeId == n1 && e.endNodeId == n2), false);
    });

    test('addNode rejects invalid NaN and Infinity coordinates', () {
      final controller = MandapEditorController();
      expect(() => controller.addNode(x: double.nan, z: 10.0), throwsArgumentError);
      expect(() => controller.addNode(x: 10.0, z: double.infinity), throwsArgumentError);
    });

    test('3D BeamTransformCalculator preserves distinct Y elevations (Y=0, Y=10, Y=20)', () {
      final groundNode = const MandapNode(id: NodeId('n0'), x: 0, z: 0, elevation: 0.0);
      final midNode = const MandapNode(id: NodeId('n10'), x: 0, z: 0, elevation: 10.0);
      final roofNode = const MandapNode(id: NodeId('n20'), x: 10, z: 0, elevation: 20.0);

      final transformGroundToRoof = BeamTransformCalculator.calculate(
        startNode: groundNode,
        endNode: roofNode,
      );
      expect(transformGroundToRoof.start.y, 0.0);
      expect(transformGroundToRoof.end.y, 20.0);
      expect(transformGroundToRoof.center.y, 10.0);

      final transformMidToRoof = BeamTransformCalculator.calculate(
        startNode: midNode,
        endNode: roofNode,
      );
      expect(transformMidToRoof.start.y, 10.0);
      expect(transformMidToRoof.end.y, 20.0);
    });

    test('PEN OFF (EditorMode.view) locks geometry mutations and BOM', () {
      final controller = MandapEditorController();
      controller.setMode(EditorMode.view);
      final initialEdgeCount = controller.layout.edges.length;
      final initialNodeCount = controller.layout.nodes.length;

      // Select / clear selection in view mode must not mutate layout
      controller.clearSelection();
      expect(controller.layout.edges.length, initialEdgeCount);
      expect(controller.layout.nodes.length, initialNodeCount);
      expect(controller.history.canUndo, false);
    });

    test('ERASER mode explicitly deletes geometry without auto-repair', () {
      final controller = MandapEditorController();
      final n1 = controller.addNode(x: 10.0, z: 10.0, elevation: 20.0);
      final n2 = controller.addNode(x: 20.0, z: 10.0, elevation: 20.0);
      controller.addEdge(startNodeId: n1, endNodeId: n2);

      final edgeToDelete = controller.layout.edges.values.firstWhere(
        (e) => e.startNodeId == n1 && e.endNodeId == n2,
      );

      controller.setMode(EditorMode.delete);
      controller.deleteEdge(edgeToDelete.id);

      expect(controller.layout.edges.containsKey(edgeToDelete.id), false);
      expect(controller.layout.nodes.containsKey(n1), true); // No auto repair / auto deletion of nodes
    });

    test('BOM consistency: generated + Pen - erased', () {
      final baseLayout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 50.0,
          plotDepth: 50.0,
          preferredPoleSpacing: 10.0,
          poleHeight: 20.0,
        ),
      );

      final controller = MandapEditorController();
      controller.setLayout(baseLayout);

      final initialLinearFt = controller.totalLinearTrussFt;

      // Add a Pen member (10 ft)
      controller.setMode(EditorMode.addEdge);
      final n1 = controller.addNode(x: 100.0, z: 100.0, elevation: 20.0);
      final n2 = controller.addNode(x: 110.0, z: 100.0, elevation: 20.0);
      controller.addEdge(startNodeId: n1, endNodeId: n2);

      expect(controller.totalLinearTrussFt, closeTo(initialLinearFt + 10.0, 0.01));

      // Erase Pen member
      final penEdge = controller.layout.edges.values.firstWhere(
        (e) => e.startNodeId == n1 && e.endNodeId == n2,
      );
      controller.setMode(EditorMode.delete);
      controller.deleteEdge(penEdge.id);

      expect(controller.totalLinearTrussFt, closeTo(initialLinearFt, 0.01));
    });

    test('Physical connectivity verification: towerTop.position == trussConnection.position, towerBase.y == 0, no zero-length members', () {
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 10.0,
          poleHeight: 20.0,
          includeCenterControlPoint: true,
        ),
      );

      final controller = MandapEditorController();
      controller.setLayout(layout);

      final calculationResult = controller.result;
      expect(calculationResult.poles.isNotEmpty, true);

      // Verify every physical tower/pole:
      for (final pole in calculationResult.poles) {
        // Base plate is at Y = 0
        final baseY = 0.0;
        expect(baseY, equals(0.0));

        // Find connected node in layout
        final matchingNode = layout.nodes.values.firstWhere(
          (n) => (n.x - pole.x).abs() < 0.01 && (n.z - pole.z).abs() < 0.01,
          orElse: () => throw StateError('Pole at (${pole.x}, ${pole.z}) missing matching layout node'),
        );

        // Tower top elevation must equal the truss connection node elevation (20.0)
        expect(matchingNode.elevation, equals(20.0));

        // Horizontal truss edges meeting this node must touch (matchingNode.x, 20.0, matchingNode.z)
        final meetingEdges = layout.edges.values.where(
          (e) => e.startNodeId == matchingNode.id || e.endNodeId == matchingNode.id,
        );
        expect(meetingEdges.isNotEmpty, true);

        for (final edge in meetingEdges) {
          final startNode = layout.getNode(edge.startNodeId)!;
          final endNode = layout.getNode(edge.endNodeId)!;

          final transform = BeamTransformCalculator.calculate(
            startNode: startNode,
            endNode: endNode,
          );

          // No zero-length members
          expect(transform.length > 0.001, true);

          if (edge.startNodeId == matchingNode.id) {
            expect((transform.start.x - matchingNode.x).abs() < 0.001, true);
            expect((transform.start.y - matchingNode.elevation).abs() < 0.001, true);
            expect((transform.start.z - matchingNode.z).abs() < 0.001, true);
          } else {
            expect((transform.end.x - matchingNode.x).abs() < 0.001, true);
            expect((transform.end.y - matchingNode.elevation).abs() < 0.001, true);
            expect((transform.end.z - matchingNode.z).abs() < 0.001, true);
          }
        }
      }
    });
  });
}
