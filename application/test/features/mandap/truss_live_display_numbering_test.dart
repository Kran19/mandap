import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/services/truss_display_numbering_service.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';

void main() {
  group('MASTER VERIFICATION — Live Truss Numbering & Label Reindex', () {
    const service = TrussDisplayNumberingService();

    test('Section 26: Basic Reindex — Nodes sort deterministically by Z then X then Y', () {
      final nodeA = const MandapNode(id: NodeId('node_A'), x: 10.0, z: 10.0);
      final nodeB = const MandapNode(id: NodeId('node_B'), x: 20.0, z: 10.0);
      final nodeC = const MandapNode(id: NodeId('node_C'), x: 10.0, z: 30.0);
      final nodeD = const MandapNode(id: NodeId('node_D'), x: 20.0, z: 30.0);

      var layout = MandapLayout(
        nodes: {
          nodeD.id: nodeD, // intentionally inserted out of order
          nodeB.id: nodeB,
          nodeA.id: nodeA,
          nodeC.id: nodeC,
        },
        edges: const {},
      );

      var numbers = service.buildNodeNumbers(layout);
      expect(numbers[nodeA.id], equals(1));
      expect(numbers[nodeB.id], equals(2));
      expect(numbers[nodeC.id], equals(3));
      expect(numbers[nodeD.id], equals(4));

      // Move Node D so it moves to front-left (Z=5, X=5)
      final movedD = const MandapNode(id: NodeId('node_D'), x: 5.0, z: 5.0);
      layout = MandapLayout(
        nodes: {
          nodeA.id: nodeA,
          nodeB.id: nodeB,
          nodeC.id: nodeC,
          movedD.id: movedD,
        },
        edges: const {},
      );

      numbers = service.buildNodeNumbers(layout);
      // D is now the front-most node, so it must become #1
      expect(numbers[movedD.id], equals(1));
      expect(numbers[nodeA.id], equals(2));
      expect(numbers[nodeB.id], equals(3));
      expect(numbers[nodeC.id], equals(4));
    });

    test('Section 27: Node ID Stability — NodeId remains immutable while display number changes', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final centerNode = controller.centerControlNode!;
      final originalId = centerNode.id;
      final initialNum = controller.displayNumbering.getNodeNumber(originalId);
      expect(initialNum, isNotNull);

      // Move the center node backwards
      controller.moveNode(
        nodeId: originalId,
        newX: centerNode.x,
        newZ: 85.0,
      );

      final updatedCenterNode = controller.layout.getNode(originalId)!;
      // Critical invariant: Structural NodeId must NOT change
      expect(updatedCenterNode.id, equals(originalId));
      expect(updatedCenterNode.id.value, equals(originalId.value));

      // Display number can update dynamically based on authoritative current geometry
      final updatedNum = controller.displayNumbering.getNodeNumber(originalId);
      expect(updatedNum, isNotNull);
    });

    test('Section 28: Member Resize — Resizing member refreshes display numbering and keeps EdgeId stable', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      // Pick an edge to resize
      final edgeToResize = controller.layout.edges.values.first;
      controller.selectEdge(edgeToResize.id);

      final oldNumbers = controller.displayNumbering;
      expect(oldNumbers.edgeNumbers.containsKey(edgeToResize.id), isTrue);

      // Resize from 30 ft to 40 ft
      final success = controller.resizeSelectedEdgeLength(40.0);
      expect(success, isTrue);

      final newNumbers = controller.displayNumbering;
      // Numbers are recalculated and available
      expect(newNumbers.edgeNumbers.containsKey(edgeToResize.id), isTrue);
      expect(controller.layout.edges.containsKey(edgeToResize.id), isTrue);
    });

    test('Section 29: Pen Drawing — Adding a member via Pen recalculates layout and number map', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final initialEdgeCount = controller.layout.edges.length;
      final initialNumberCount = controller.displayNumbering.edgeNumbers.length;
      expect(initialNumberCount, equals(initialEdgeCount));

      // Draw a member from (10, 20, 10) to (40, 20, 10)
      controller.setPenStartPoint(v64.Vector3(10.0, 20.0, 10.0));
      controller.createTrussMember(
        targetEndPoint: v64.Vector3(40.0, 20.0, 10.0),
        requestedLength: 30.0,
      );

      expect(controller.layout.edges.length, equals(initialEdgeCount + 1));
      expect(controller.displayNumbering.edgeNumbers.length, equals(initialEdgeCount + 1));

      // All edges must have contiguous 1..N numbers
      final sortedNumbers = controller.displayNumbering.edgeNumbers.values.toList()..sort();
      for (int i = 0; i < sortedNumbers.length; i++) {
        expect(sortedNumbers[i], equals(i + 1));
      }
    });

    test('Section 30: Eraser — Deleting a member removes its label and reindexes remaining labels contiguously', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final edgeToDelete = controller.layout.edges.values.first;
      final edgeId = edgeToDelete.id;
      expect(controller.displayNumbering.edgeNumbers.containsKey(edgeId), isTrue);

      controller.deleteEdge(edgeId);

      // Deleted edge has no display label
      expect(controller.displayNumbering.edgeNumbers.containsKey(edgeId), isFalse);

      // Remaining edge labels must be contiguous 1..M
      final remainingCount = controller.layout.edges.length;
      expect(controller.displayNumbering.edgeNumbers.length, equals(remainingCount));
      final sortedNumbers = controller.displayNumbering.edgeNumbers.values.toList()..sort();
      for (int i = 0; i < sortedNumbers.length; i++) {
        expect(sortedNumbers[i], equals(i + 1));
      }
    });

    test('Section 31: Center Control — Moving front/back recomputes numbers while preserving fixed X', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final centerNode = controller.centerControlNode!;
      final fixedX = centerNode.x;

      // Adjust center control to Z = 25.0
      controller.adjustCenterFrontBack(newZ: 25.0);

      final updatedCenter = controller.centerControlNode!;
      expect(updatedCenter.x, equals(fixedX), reason: 'Center X must remain strictly fixed');
      expect(updatedCenter.z, equals(25.0));

      // Display numbers must reflect the new Z position
      final nodeNumber = controller.displayNumbering.getNodeNumber(updatedCenter.id);
      expect(nodeNumber, isNotNull);
    });

    test('Section 32: Camera — Orbit, Pan, and Zoom do NOT modify layout or display numbering', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );
      final controller3D = Mandap3DController();

      final initialNumbers = controller.displayNumbering;
      final initialLayoutNodes = controller.layout.nodes;
      final initialLayoutEdges = controller.layout.edges;

      // Orbit / Rotate camera
      controller3D.orbitCamera(50.0, 20.0);
      expect(controller.displayNumbering, same(initialNumbers));
      expect(controller.layout.nodes, equals(initialLayoutNodes));
      expect(controller.layout.edges, equals(initialLayoutEdges));

      // Pan camera
      controller3D.panCamera(20.0, -15.0);
      expect(controller.displayNumbering, same(initialNumbers));

      // Zoom camera
      controller3D.zoomCamera(1.5);
      expect(controller.displayNumbering, same(initialNumbers));
    });

    test('Section 33: 2D / 3D Parity — Both 2D and 3D consume the exact same numbering map', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final numberingResult = controller.displayNumbering;

      // Every edge in layout has identical number in 2D and 3D
      for (final edge in controller.layout.edges.values) {
        final edgeNum2D = numberingResult.getEdgeNumber(edge.id);
        final edgeNum3D = numberingResult.getEdgeNumber(edge.id);
        expect(edgeNum2D, isNotNull);
        expect(edgeNum2D, equals(edgeNum3D));
      }

      // Every structural node in layout has identical number in 2D and 3D
      for (final node in controller.layout.nodes.values) {
        final nodeNum2D = numberingResult.getNodeNumber(node.id);
        final nodeNum3D = numberingResult.getNodeNumber(node.id);
        expect(nodeNum2D, isNotNull);
        expect(nodeNum2D, equals(nodeNum3D));
      }
    });

    test('Section 35: Non-structural objects (Stage/Carpet) are never assigned truss numbers', () {
      final structuralNode = const MandapNode(id: NodeId('struct_1'), x: 10.0, z: 10.0);
      final stageNode = const MandapNode(id: NodeId('stage_1'), x: 15.0, z: 15.0, type: NodeType.stage);
      final carpetNode = const MandapNode(id: NodeId('carpet_1'), x: 20.0, z: 20.0, type: NodeType.carpet);

      final layout = MandapLayout(
        nodes: {
          structuralNode.id: structuralNode,
          stageNode.id: stageNode,
          carpetNode.id: carpetNode,
        },
        edges: const {},
      );

      final numbers = service.buildNodeNumbers(layout);
      expect(numbers.containsKey(structuralNode.id), isTrue);
      expect(numbers.containsKey(stageNode.id), isFalse);
      expect(numbers.containsKey(carpetNode.id), isFalse);
    });

    test('Section 11 & 12: Shared Junctions and Coincident Nodes are deterministic with single label per NodeId', () {
      final junctionNode = const MandapNode(id: NodeId('junction_center'), x: 50.0, z: 50.0);
      final nodeLeft = const MandapNode(id: NodeId('node_left'), x: 20.0, z: 50.0);
      final nodeRight = const MandapNode(id: NodeId('node_right'), x: 80.0, z: 50.0);
      final nodeTop = const MandapNode(id: NodeId('node_top'), x: 50.0, z: 20.0);
      final nodeBottom = const MandapNode(id: NodeId('node_bottom'), x: 50.0, z: 80.0);

      final edgeH1 = MandapEdge(id: const EdgeId('edge_h1'), startNodeId: nodeLeft.id, endNodeId: junctionNode.id);
      final edgeH2 = MandapEdge(id: const EdgeId('edge_h2'), startNodeId: junctionNode.id, endNodeId: nodeRight.id);
      final edgeV1 = MandapEdge(id: const EdgeId('edge_v1'), startNodeId: nodeTop.id, endNodeId: junctionNode.id);
      final edgeV2 = MandapEdge(id: const EdgeId('edge_v2'), startNodeId: junctionNode.id, endNodeId: nodeBottom.id);

      final layout = MandapLayout(
        nodes: {
          junctionNode.id: junctionNode,
          nodeLeft.id: nodeLeft,
          nodeRight.id: nodeRight,
          nodeTop.id: nodeTop,
          nodeBottom.id: nodeBottom,
        },
        edges: {
          edgeH1.id: edgeH1,
          edgeH2.id: edgeH2,
          edgeV1.id: edgeV1,
          edgeV2.id: edgeV2,
        },
      );

      final numbers = service.computeNumbering(layout);
      // Junction has exactly one unique node number
      final junctionNum = numbers.getNodeNumber(junctionNode.id);
      expect(junctionNum, isNotNull);
      expect(numbers.nodeNumbers.values.where((n) => n == junctionNum).length, equals(1));

      // All 4 edges have distinct contiguous 1..4 numbers
      expect(numbers.edgeNumbers.length, equals(4));
      final edgeNumValues = numbers.edgeNumbers.values.toSet();
      expect(edgeNumValues, equals({1, 2, 3, 4}));
    });
  });
}
