import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('AutoConnectPoles Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        engine: const MandapCalculationEngine(),
      );
      controller.clearAll();
    });

    test('Does not auto-connect when fewer than 4 unconnected poles exist', () {
      controller.addNodeNamed(x: 0, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      controller.addNodeNamed(x: 30, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      controller.addNodeNamed(x: 30, z: 40, type: NodeType.pole, support: NodeSupport.pole);

      final didConnect = controller.autoConnectUnconnectedPoles();
      expect(didConnect, isFalse);
      expect(controller.layout.edges.length, 0);
    });

    test('Automatically connects 4 poles in perimeter order with 4 truss edges', () {
      // Place 4 poles
      final p1 = controller.addNodeNamed(x: 0, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      final p2 = controller.addNodeNamed(x: 40, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      final p3 = controller.addNodeNamed(x: 40, z: 30, type: NodeType.pole, support: NodeSupport.pole);
      final p4 = controller.addNodeNamed(x: 0, z: 30, type: NodeType.pole, support: NodeSupport.pole);

      expect(p1, isNotNull);
      expect(p2, isNotNull);
      expect(p3, isNotNull);
      expect(p4, isNotNull);
      expect(controller.layout.edges.length, 0);

      final didConnect = controller.autoConnectUnconnectedPoles();
      expect(didConnect, isTrue);

      // Verify 4 edges created
      expect(controller.layout.edges.length, 4);

      // Verify each pole has exactly 2 connecting edges (closed perimeter loop)
      for (final poleId in [p1!, p2!, p3!, p4!]) {
        final connectedEdges = controller.layout.edges.values.where(
          (e) => e.startNodeId == poleId || e.endNodeId == poleId,
        ).toList();
        expect(connectedEdges.length, 2);
      }
    });

    test('Auto-connect supports Undo and Redo cleanly', () {
      controller.addNodeNamed(x: 0, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      controller.addNodeNamed(x: 20, z: 0, type: NodeType.pole, support: NodeSupport.pole);
      controller.addNodeNamed(x: 20, z: 20, type: NodeType.pole, support: NodeSupport.pole);
      controller.addNodeNamed(x: 0, z: 20, type: NodeType.pole, support: NodeSupport.pole);

      final didConnect = controller.autoConnectUnconnectedPoles();
      expect(didConnect, isTrue);
      expect(controller.layout.edges.length, 4);

      // Undo auto-connect
      controller.undo();
      expect(controller.layout.edges.length, 0);
      expect(controller.layout.nodes.length, 4);

      // Redo auto-connect
      controller.redo();
      expect(controller.layout.edges.length, 4);
    });
  });

  group('SplitEdgeWithPole Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        engine: const MandapCalculationEngine(),
      );
      controller.clearAll();
    });

    test('Splits 1 truss line into 2 separate segments when a pole is created in the center', () {
      final p1 = controller.addNodeNamed(x: 0, z: 0, type: NodeType.pole, support: NodeSupport.pole)!;
      final p2 = controller.addNodeNamed(x: 60, z: 0, type: NodeType.pole, support: NodeSupport.pole)!;
      final p3 = controller.addNodeNamed(x: 60, z: 30, type: NodeType.pole, support: NodeSupport.pole)!;
      final p4 = controller.addNodeNamed(x: 0, z: 30, type: NodeType.pole, support: NodeSupport.pole)!;

      controller.autoConnectUnconnectedPoles();
      expect(controller.layout.edges.length, 4);

      // Find edge along z=0 (p1 -> p2 of 60 ft)
      final edgeAlongTop = controller.findEdgePassingThrough(30, 0);
      expect(edgeAlongTop, isNotNull);

      // Split the 60 ft edge at center (30, 0)
      final midPoleId = controller.splitEdgeWithPole(edgeAlongTop!, x: 30, z: 0);
      expect(midPoleId, isNotNull);

      // Layout has 6 edges total (the 60ft edge and its parallel opposite perimeter edge were split into 2 each)
      expect(controller.layout.edges.length, 6);

      final midPoleNode = controller.layout.getNode(midPoleId!);
      expect(midPoleNode, isNotNull);
      expect(midPoleNode!.x, 30.0);
      expect(midPoleNode.z, 0.0);
      expect(midPoleNode.support, NodeSupport.pole);

      // Verify the 2 new edges connected to midPoleNode
      final edgesAtMid = controller.layout.edges.values.where(
        (e) => e.startNodeId == midPoleId || e.endNodeId == midPoleId,
      ).toList();
      expect(edgesAtMid.length, 2);

      // Verify Undo restores the 4 original edges and Redo splits them back
      controller.undo();
      if (controller.layout.edges.length == 5) {
        controller.undo();
      }
      expect(controller.layout.edges.length, 4);
      expect(controller.layout.getNode(midPoleId), isNull);

      controller.redo();
      controller.redo();
      expect(controller.layout.edges.length, 6);
      expect(controller.layout.getNode(midPoleId), isNotNull);
    });
  });
}
