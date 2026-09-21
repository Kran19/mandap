import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('Selected Truss Member Length Control Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(engine: const MandapCalculationEngine());
    });

    test('Test 1 — Resize: 10 ft -> 14 ft', () {
      final nodeA = MandapNode(
        id: const NodeId('node_A'),
        x: 0.0,
        z: 0.0,
        elevation: 10.0,
        type: NodeType.corner,
      );
      final nodeB = MandapNode(
        id: const NodeId('node_B'),
        x: 10.0,
        z: 0.0,
        elevation: 10.0,
        type: NodeType.corner,
      );
      final edgeAB = MandapEdge(
        id: const EdgeId('edge_AB'),
        startNodeId: nodeA.id,
        endNodeId: nodeB.id,
        profile: EdgeProfile.box,
      );

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB},
        edges: {edgeAB.id: edgeAB},
      ));

      controller.selectEdge(edgeAB.id);
      expect(controller.selectedEdgeLength, closeTo(10.0, 1e-4));

      // Resize from 10 ft to 14 ft
      final success = controller.resizeSelectedEdgeLength(14.0);
      expect(success, isTrue);

      expect(controller.selectedEdgeLength, closeTo(14.0, 1e-4));
      final updatedEdge = controller.layout.getEdge(edgeAB.id)!;
      final updatedLen = controller.layout.getExactGeometricLengthFeet(updatedEdge);
      expect(updatedLen, closeTo(14.0, 1e-4));
    });

    test('Test 2 — Unrelated members remain strictly unchanged', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 10.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 10.0);
      final nodeC = MandapNode(id: const NodeId('node_C'), x: 0.0, z: 20.0, elevation: 10.0);
      final nodeD = MandapNode(id: const NodeId('node_D'), x: 15.0, z: 20.0, elevation: 10.0);

      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);
      final edgeCD = MandapEdge(id: const EdgeId('edge_CD'), startNodeId: nodeC.id, endNodeId: nodeD.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB, nodeC.id: nodeC, nodeD.id: nodeD},
        edges: {edgeAB.id: edgeAB, edgeCD.id: edgeCD},
      ));

      final cdStartNodeBefore = controller.layout.getNode(edgeCD.startNodeId)!;
      final cdEndNodeBefore = controller.layout.getNode(edgeCD.endNodeId)!;
      final cdLengthBefore = controller.layout.getExactGeometricLengthFeet(edgeCD);
      final cdProfileBefore = edgeCD.profile;

      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(16.0);

      // Verify selected edge is resized
      expect(controller.selectedEdgeLength, closeTo(16.0, 1e-4));

      // Verify unrelated edge CD is completely unchanged
      final cdEdgeAfter = controller.layout.getEdge(edgeCD.id)!;
      final cdStartNodeAfter = controller.layout.getNode(cdEdgeAfter.startNodeId)!;
      final cdEndNodeAfter = controller.layout.getNode(cdEdgeAfter.endNodeId)!;
      final cdLengthAfter = controller.layout.getExactGeometricLengthFeet(cdEdgeAfter);

      expect(cdStartNodeAfter.x, equals(cdStartNodeBefore.x));
      expect(cdStartNodeAfter.z, equals(cdStartNodeBefore.z));
      expect(cdStartNodeAfter.elevation, equals(cdStartNodeBefore.elevation));

      expect(cdEndNodeAfter.x, equals(cdEndNodeBefore.x));
      expect(cdEndNodeAfter.z, equals(cdEndNodeBefore.z));
      expect(cdEndNodeAfter.elevation, equals(cdEndNodeBefore.elevation));

      expect(cdLengthAfter, equals(cdLengthBefore));
      expect(cdEdgeAfter.profile, equals(cdProfileBefore));
    });

    test('Test 3 — Shared endpoint protection (A ── B ── C: resize A-B, B-C untouched)', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 12.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 12.0);
      final nodeC = MandapNode(id: const NodeId('node_C'), x: 20.0, z: 0.0, elevation: 12.0);

      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);
      final edgeBC = MandapEdge(id: const EdgeId('edge_BC'), startNodeId: nodeB.id, endNodeId: nodeC.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB, nodeC.id: nodeC},
        edges: {edgeAB.id: edgeAB, edgeBC.id: edgeBC},
      ));

      final originalNodeBPos = v64.Vector3(nodeB.x, nodeB.elevation, nodeB.z);
      final bcLenBefore = controller.layout.getExactGeometricLengthFeet(edgeBC);

      // Select edge A-B and resize from 10 to 14 ft
      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(14.0);

      // Edge A-B resized to 14 ft
      final abAfter = controller.layout.getEdge(edgeAB.id)!;
      expect(controller.layout.getExactGeometricLengthFeet(abAfter), closeTo(14.0, 1e-4));

      // Edge B-C is 100% UNCHANGED
      final bcAfter = controller.layout.getEdge(edgeBC.id)!;
      final currentStartNodeOfBC = controller.layout.getNode(bcAfter.startNodeId)!;
      final currentEndNodeOfBC = controller.layout.getNode(bcAfter.endNodeId)!;

      expect(bcAfter.startNodeId, equals(nodeB.id));
      expect(bcAfter.endNodeId, equals(nodeC.id));
      expect(currentStartNodeOfBC.x, equals(originalNodeBPos.x));
      expect(currentStartNodeOfBC.z, equals(originalNodeBPos.z));
      expect(controller.layout.getExactGeometricLengthFeet(bcAfter), closeTo(bcLenBefore, 1e-4));
    });

    test('Test 4 — BOM reflects new geometric length', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 10.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 10.0);
      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB},
        edges: {edgeAB.id: edgeAB},
      ));

      final initialLinearFt = controller.totalLinearTrussFt;
      expect(initialLinearFt, closeTo(10.0, 1e-4));

      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(14.0);

      expect(controller.totalLinearTrussFt, closeTo(14.0, 1e-4));
    });

    test('Test 5 — Undo restores 10 ft from 14 ft', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 10.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 10.0);
      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB},
        edges: {edgeAB.id: edgeAB},
      ));

      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(14.0);
      expect(controller.layout.getExactGeometricLengthFeet(controller.layout.getEdge(edgeAB.id)!), closeTo(14.0, 1e-4));

      // Undo
      expect(controller.canUndo, isTrue);
      controller.undo();

      final restoredEdge = controller.layout.getEdge(edgeAB.id)!;
      expect(controller.layout.getExactGeometricLengthFeet(restoredEdge), closeTo(10.0, 1e-4));
      final movingNode = controller.layout.getNode(restoredEdge.endNodeId)!;
      expect(movingNode.x, closeTo(10.0, 1e-4));
      expect(movingNode.z, closeTo(0.0, 1e-4));
    });

    test('Test 6 — Redo restores 14 ft from 10 ft', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 10.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 10.0);
      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB},
        edges: {edgeAB.id: edgeAB},
      ));

      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(14.0);

      controller.undo();
      expect(controller.layout.getExactGeometricLengthFeet(controller.layout.getEdge(edgeAB.id)!), closeTo(10.0, 1e-4));

      expect(controller.canRedo, isTrue);
      controller.redo();

      final redoneEdge = controller.layout.getEdge(edgeAB.id)!;
      expect(controller.layout.getExactGeometricLengthFeet(redoneEdge), closeTo(14.0, 1e-4));
      final movingNode = controller.layout.getNode(redoneEdge.endNodeId)!;
      expect(movingNode.x, closeTo(14.0, 1e-4));
      expect(movingNode.z, closeTo(0.0, 1e-4));
    });

    test('Test 7 — Direction: X-axis member remains X-axis, Z-axis member remains Z-axis', () {
      // 1. X-axis member
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 5.0, z: 12.0, elevation: 15.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 15.0, z: 12.0, elevation: 15.0);
      final edgeX = MandapEdge(id: const EdgeId('edge_X'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);

      // 2. Z-axis member
      final nodeC = MandapNode(id: const NodeId('node_C'), x: 30.0, z: 5.0, elevation: 15.0);
      final nodeD = MandapNode(id: const NodeId('node_D'), x: 30.0, z: 15.0, elevation: 15.0);
      final edgeZ = MandapEdge(id: const EdgeId('edge_Z'), startNodeId: nodeC.id, endNodeId: nodeD.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB, nodeC.id: nodeC, nodeD.id: nodeD},
        edges: {edgeX.id: edgeX, edgeZ.id: edgeZ},
      ));

      // Resize X-axis edge
      controller.selectEdge(edgeX.id);
      controller.resizeSelectedEdgeLength(20.0);
      final updatedEdgeX = controller.layout.getEdge(edgeX.id)!;
      final startX = controller.layout.getNode(updatedEdgeX.startNodeId)!;
      final endX = controller.layout.getNode(updatedEdgeX.endNodeId)!;

      expect(startX.z, equals(endX.z)); // Strict X-axis alignment preserved!
      expect((endX.x - startX.x).abs(), closeTo(20.0, 1e-4));

      // Resize Z-axis edge
      controller.selectEdge(edgeZ.id);
      controller.resizeSelectedEdgeLength(25.0);
      final updatedEdgeZ = controller.layout.getEdge(edgeZ.id)!;
      final startZ = controller.layout.getNode(updatedEdgeZ.startNodeId)!;
      final endZ = controller.layout.getNode(updatedEdgeZ.endNodeId)!;

      expect(startZ.x, equals(endZ.x)); // Strict Z-axis alignment preserved!
      expect((endZ.z - startZ.z).abs(), closeTo(25.0, 1e-4));
    });

    test('Test 8 — 2D / 3D parity: Both show identical world coordinates', () {
      final nodeA = MandapNode(id: const NodeId('node_A'), x: 0.0, z: 0.0, elevation: 10.0);
      final nodeB = MandapNode(id: const NodeId('node_B'), x: 10.0, z: 0.0, elevation: 10.0);
      final edgeAB = MandapEdge(id: const EdgeId('edge_AB'), startNodeId: nodeA.id, endNodeId: nodeB.id, profile: EdgeProfile.box);

      controller.setLayout(MandapLayout(
        nodes: {nodeA.id: nodeA, nodeB.id: nodeB},
        edges: {edgeAB.id: edgeAB},
      ));

      controller.selectEdge(edgeAB.id);
      controller.resizeSelectedEdgeLength(14.0);

      final authoritativeEdge = controller.layout.getEdge(edgeAB.id)!;
      final sNode = controller.layout.getNode(authoritativeEdge.startNodeId)!;
      final eNode = controller.layout.getNode(authoritativeEdge.endNodeId)!;

      // 2D World domain
      final len2D = math.sqrt(math.pow(eNode.x - sNode.x, 2) + math.pow(eNode.z - sNode.z, 2));

      // 3D World domain
      final p1_3D = v64.Vector3(sNode.x, sNode.elevation, sNode.z);
      final p2_3D = v64.Vector3(eNode.x, eNode.elevation, eNode.z);
      final len3D = p1_3D.distanceTo(p2_3D);

      expect(len2D, closeTo(14.0, 1e-4));
      expect(len3D, closeTo(14.0, 1e-4));
      expect(len2D, equals(len3D));
    });
  });
}
