import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';
import 'package:mandap/features/mandap/domain/services/truss_bom_calculator.dart';
import 'package:mandap/features/mandap/domain/services/truss_support_spacing_calculator.dart';
import 'package:mandap/features/mandap/domain/value_objects/truss_bom_summary.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';

void main() {
  group('MASTER PROMPT — MANDAP BUILDER TRUSS: SEPARATE PILLAR & UPPER TRUSS BOM', () {
    const calc = TrussBomCalculator();

    // ── Test 1: Pillar Members Classified Correctly ──────────────────────────
    test('1. Pillar members classified correctly (abs(dy) > tol && dx <= tol && dz <= tol or role: tower)', () {
      const nGround = MandapNode(id: NodeId('g1'), x: 20.0, z: 20.0, elevation: 0.0);
      const nTop = MandapNode(id: NodeId('t1'), x: 20.0, z: 20.0, elevation: 30.0);
      final edge = MandapEdge(
        id: const EdgeId('e_tower_1'),
        startNodeId: nGround.id,
        endNodeId: nTop.id,
        role: TrussMemberRole.tower,
      );
      final layout = MandapLayout(
        nodes: {nGround.id: nGround, nTop.id: nTop},
        edges: {edge.id: edge},
      );

      final category = calc.classifyEdge(layout, edge);
      expect(category, equals(TrussMemberCategory.pillar));

      final bom = calc.calculateBom(layout);
      expect(bom.pillarQuantity, equals(1));
      expect(bom.pillarTotalFeet, closeTo(30.0, 0.001));
      expect(bom.upperQuantity, equals(0));
      expect(bom.totalQuantity, equals(1));
      expect(bom.totalFeet, closeTo(30.0, 0.001));
    });

    // ── Test 2: Upper Members Classified Correctly ────────────────────────────
    test('2. Upper members classified correctly (horizontal flat dy ≈ 0)', () {
      const n1 = MandapNode(id: NodeId('u1'), x: 0.0, z: 30.0, elevation: 20.0);
      const n2 = MandapNode(id: NodeId('u2'), x: 30.0, z: 30.0, elevation: 20.0);
      final edge = MandapEdge(
        id: const EdgeId('e_perim_1'),
        startNodeId: n1.id,
        endNodeId: n2.id,
        role: TrussMemberRole.upper,
      );
      final layout = MandapLayout(
        nodes: {n1.id: n1, n2.id: n2},
        edges: {edge.id: edge},
      );

      final category = calc.classifyEdge(layout, edge);
      expect(category, equals(TrussMemberCategory.upper));

      final bom = calc.calculateBom(layout);
      expect(bom.upperQuantity, equals(1));
      expect(bom.upperTotalFeet, closeTo(30.0, 0.001));
      expect(bom.pillarQuantity, equals(0));
      expect(bom.totalQuantity, equals(1));
      expect(bom.totalFeet, closeTo(30.0, 0.001));
    });

    // ── Test 3: Sloped Roof Apex Members Remain Upper ────────────────────────
    test('3. Sloped roof members connected to apex/center control remain Upper when dy != 0', () {
      const nPerim = MandapNode(id: NodeId('p1'), x: 0.0, z: 50.0, elevation: 20.0);
      const nApex = MandapNode(
        id: NodeId('apex'),
        x: 50.0,
        z: 50.0,
        elevation: 25.0, // Raised apex (dy = 5.0)
        type: NodeType.controlPoint,
      );
      final edge = MandapEdge(
        id: const EdgeId('e_apex_1'),
        startNodeId: nPerim.id,
        endNodeId: nApex.id,
        role: TrussMemberRole.upper,
      );
      final layout = MandapLayout(
        nodes: {nPerim.id: nPerim, nApex.id: nApex},
        edges: {edge.id: edge},
      );

      final category = calc.classifyEdge(layout, edge);
      expect(category, equals(TrussMemberCategory.upper),
          reason: 'Sloped roof member connecting to apex must remain Upper, not become Pillar');

      final expected3DLength = math.sqrt(50 * 50 + 5 * 5); // sqrt(2525) ≈ 50.249
      final bom = calc.calculateBom(layout);
      expect(bom.upperQuantity, equals(1));
      expect(bom.upperTotalFeet, closeTo(expected3DLength, 0.01));
      expect(bom.pillarQuantity, equals(0));
    });

    // ── Test 4: 100-ft Run Produces 30 + 30 + 30 + 10 Segmentation ───────────
    test('4. 100-ft run produces 30 + 30 + 30 + 10 geometric lengths (final remainder preserved)', () {
      const spacingCalc = TrussSupportSpacingCalculator();
      final segments = spacingCalc.calculateSegments(100.0, interval: 30.0);
      expect(segments.length, equals(4));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(30.0));
      expect(segments[2].length, equals(30.0));
      expect(segments[3].length, equals(10.0));

      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 30.0,
          poleHeight: 20.0,
          includeCenterControlPoint: true,
          includeTowerEdges: true,
        ),
      );

      // Verify South perimeter edges (elevation = 20, z = 0) have lengths 10, 30, 30, 30
      final southEdges = layout.edges.values.where((e) {
        if (e.role != TrussMemberRole.upper) return false;
        final s = layout.getNode(e.startNodeId)!;
        final end = layout.getNode(e.endNodeId)!;
        return s.z == 0.0 && end.z == 0.0 && s.elevation == 20.0 && end.elevation == 20.0;
      }).toList();

      final lengths = southEdges.map((e) => layout.get3DGeometricLengthFeet(e)).toList()..sort();
      expect(lengths, equals([10.0, 30.0, 30.0, 30.0]));
    });

    // ── Test 5: Pillar Quantity Independent From Pole Count ──────────────────
    test('5. Pillar quantity is independent from pole count (calculated from actual MandapEdge geometry)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final bom = controller.trussBomSummary;
      final poleCount = controller.totalPoleCount;

      expect(bom.pillarQuantity, greaterThan(0));
      expect(poleCount, greaterThan(0));
      // Domain edges define the BOM, not pole count assumptions
      expect(bom.pillarMembers.length, equals(bom.pillarQuantity));
    });

    // ── Test 6: Upper Quantity Independent From Pillar Quantity ───────────────
    test('6. Upper quantity is independent from pillar quantity', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final bom = controller.trussBomSummary;
      // 16 perimeter segments + 4 internal cross = 20 upper members
      expect(bom.upperQuantity, equals(20));
      // 16 perimeter towers = 16 pillar members (or 17 if center has ground tower)
      expect(bom.pillarQuantity, greaterThanOrEqualTo(16));
    });

    // ── Test 7 & 8: Total = Pillar + Upper (Quantity and Feet) ─────────────────
    test('7 & 8. Total Quantity = Pillar + Upper, Total Feet = Pillar Feet + Upper Feet', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final bom = controller.trussBomSummary;
      expect(bom.totalQuantity, equals(bom.pillarQuantity + bom.upperQuantity));
      expect(bom.totalFeet, closeTo(bom.pillarTotalFeet + bom.upperTotalFeet, 0.001));

      // Controller convenience getters match
      expect(controller.pillarQuantity, equals(bom.pillarQuantity));
      expect(controller.pillarTotalFeet, equals(bom.pillarTotalFeet));
      expect(controller.upperQuantity, equals(bom.upperQuantity));
      expect(controller.upperTotalFeet, equals(bom.upperTotalFeet));
      expect(controller.totalTrussQuantity, equals(bom.totalQuantity));
      expect(controller.totalTrussFeet, equals(bom.totalFeet));
    });

    // ── Test 9: Resize Upper Member Affects Only Upper BOM ────────────────────
    test('9. Resizing an Upper member (+4 ft) increases Upper Feet and Total Feet by 4 ft, Pillar unchanged', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialPillarFt = controller.pillarTotalFeet;
      final initialUpperFt = controller.upperTotalFeet;
      final initialTotalFt = controller.totalTrussFeet;

      // Select a 10 ft upper member
      final tenFtEdge = controller.layout.edges.values.firstWhere(
        (e) => e.role == TrussMemberRole.upper &&
            (controller.layout.get3DGeometricLengthFeet(e) - 10.0).abs() < 0.1,
      );

      controller.selectEdge(tenFtEdge.id);
      final resized = controller.resizeSelectedEdgeLength(14.0);
      expect(resized, isTrue);

      final updatedBom = controller.trussBomSummary;
      expect(updatedBom.pillarTotalFeet, closeTo(initialPillarFt, 0.001),
          reason: 'Pillar feet must remain strictly unchanged when an upper member is resized');
      expect(updatedBom.upperTotalFeet, closeTo(initialUpperFt + 4.0, 0.001),
          reason: 'Upper feet must increase by exactly 4 ft');
      expect(updatedBom.totalFeet, closeTo(initialTotalFt + 4.0, 0.001),
          reason: 'Total feet must increase by exactly 4 ft');
    });

    // ── Test 10: Resize Pillar Member Affects Only Pillar BOM ─────────────────
    test('10. Resizing a Pillar member (+4 ft) increases Pillar Feet and Total Feet by 4 ft, Upper unchanged', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialPillarFt = controller.pillarTotalFeet;
      final initialUpperFt = controller.upperTotalFeet;
      final initialTotalFt = controller.totalTrussFeet;

      // Select a 20 ft pillar member
      final pillarEdge = controller.layout.edges.values.firstWhere(
        (e) => e.role == TrussMemberRole.tower,
      );

      controller.selectEdge(pillarEdge.id);
      final resized = controller.resizeSelectedEdgeLength(24.0);
      expect(resized, isTrue);

      final updatedBom = controller.trussBomSummary;
      expect(updatedBom.upperTotalFeet, closeTo(initialUpperFt, 0.001),
          reason: 'Upper feet must remain strictly unchanged when a pillar member is resized');
      expect(updatedBom.pillarTotalFeet, closeTo(initialPillarFt + 4.0, 0.001),
          reason: 'Pillar feet must increase by exactly 4 ft');
      expect(updatedBom.totalFeet, closeTo(initialTotalFt + 4.0, 0.001),
          reason: 'Total feet must increase by exactly 4 ft');
    });

    // ── Test 11: Center Apex Elevation Changes Upper Geometry, Not Pillar BOM ─
    test('11. Raising center control elevation updates Upper geometric lengths, Pillar BOM unchanged', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialPillarCount = controller.pillarQuantity;
      final initialPillarFt = controller.pillarTotalFeet;
      final initialUpperFt = controller.upperTotalFeet;

      // Raise center apex from 20.0 to 25.0 ft (dy = 5 ft)
      final centerNode = controller.centerControlNode!;
      controller.applyAdjustCenterControl(
                newX: centerNode.x,
        newZ: centerNode.z,
        newElevation: 25.0,
      );

      final updatedBom = controller.trussBomSummary;
      expect(updatedBom.pillarQuantity, equals(initialPillarCount),
          reason: 'Pillar quantity must not change when center apex is raised');
      expect(updatedBom.pillarTotalFeet, closeTo(initialPillarFt, 0.001),
          reason: 'Pillar total feet must not change when center apex is raised');

      // Connected cross members were 50 ft; now sqrt(50^2 + 5^2) ≈ 50.249 ft each (+0.249 * 4 = +0.997 ft)
      expect(updatedBom.upperTotalFeet, greaterThan(initialUpperFt),
          reason: 'Upper total feet must increase due to 3D sloped Euclidean length');
      expect(updatedBom.upperQuantity, equals(20),
          reason: 'Sloped roof members must still be classified as Upper');
    });

    // ── Test 12: Pen-Created Member Appears In BOM As Upper/Custom ────────────
    test('12. Pen-created member appears in BOM (defaults to Upper/custom, never auto-converted to Pillar)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialUpperQty = controller.upperQuantity;
      final initialPillarQty = controller.pillarQuantity;

      // Draw a vertical line with Pen tool (from Y=0 to Y=15 at (200, 200))
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(v64.Vector3(200.0, 0.0, 200.0));
      controller.createTrussMember(
        targetEndPoint: v64.Vector3(200.0, 15.0, 200.0),
      );

      final updatedBom = controller.trussBomSummary;
      expect(updatedBom.upperQuantity, equals(initialUpperQty + 1),
          reason: 'Pen-drawn member defaults to Upper/custom BOM');
      expect(updatedBom.pillarQuantity, equals(initialPillarQty),
          reason: 'Pen-drawn vertical member must NOT automatically become a Pillar tower');
    });

    // ── Test 13: Deletion of Member Updates Respective Category ───────────────
    test('13. Deleting an Upper member decreases Upper BOM, Pillar BOM unchanged', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialUpperQty = controller.upperQuantity;
      final initialPillarQty = controller.pillarQuantity;
      final initialPillarFt = controller.pillarTotalFeet;

      // Delete one upper perimeter edge
      final edgeToDelete = controller.layout.edges.values.firstWhere(
        (e) => e.role == TrussMemberRole.upper,
      );
      final deletedLen = controller.layout.get3DGeometricLengthFeet(edgeToDelete);

      controller.deleteEdge(edgeToDelete.id);

      final updatedBom = controller.trussBomSummary;
      expect(updatedBom.upperQuantity, equals(initialUpperQty - 1));
      expect(updatedBom.pillarQuantity, equals(initialPillarQty),
          reason: 'Deleting upper member leaves pillar quantity unchanged');
      expect(updatedBom.pillarTotalFeet, closeTo(initialPillarFt, 0.001),
          reason: 'Deleting upper member leaves pillar feet unchanged');
    });

    // ── Test 14 & 15: Undo / Redo Preserves Exact BOM ─────────────────────────
    test('14 & 15. Undo restores exact BOM; Redo reapplies exact BOM', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final initialBom = controller.trussBomSummary;

      // Perform a mutation: resize an upper member from 10 to 14 ft
      final tenFtEdge = controller.layout.edges.values.firstWhere(
        (e) => e.role == TrussMemberRole.upper &&
            (controller.layout.get3DGeometricLengthFeet(e) - 10.0).abs() < 0.1,
      );
      controller.selectEdge(tenFtEdge.id);
      controller.resizeSelectedEdgeLength(14.0);

      final mutatedBom = controller.trussBomSummary;
      expect(mutatedBom.totalFeet, closeTo(initialBom.totalFeet + 4.0, 0.001));

      // Undo
      controller.undo();
      final undoneBom = controller.trussBomSummary;
      expect(undoneBom.totalFeet, closeTo(initialBom.totalFeet, 0.001));
      expect(undoneBom.pillarTotalFeet, closeTo(initialBom.pillarTotalFeet, 0.001));
      expect(undoneBom.upperTotalFeet, closeTo(initialBom.upperTotalFeet, 0.001));
      expect(undoneBom.totalQuantity, equals(initialBom.totalQuantity));

      // Redo
      controller.redo();
      final redoneBom = controller.trussBomSummary;
      expect(redoneBom.totalFeet, closeTo(mutatedBom.totalFeet, 0.001));
      expect(redoneBom.totalQuantity, equals(mutatedBom.totalQuantity));
    });

    // ── Test 16: Camera Movement Does Not Alter BOM ──────────────────────────
    test('16. Camera orbit, pan, and zoom do NOT modify layout or BOM', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );
      final controller3D = Mandap3DController();

      final initialBom = controller.trussBomSummary;

      // Orbit camera
      controller3D.orbitCamera(45.0, 30.0);
      expect(controller.trussBomSummary, equals(initialBom));

      // Pan camera
      controller3D.panCamera(15.0, -10.0);
      expect(controller.trussBomSummary, equals(initialBom));

      // Zoom camera
      controller3D.zoomCamera(1.2);
      expect(controller.trussBomSummary, equals(initialBom));
    });

    // ── Test 17: Zero Double-Counting of Edges ────────────────────────────────
    test('17. Duplicate edges are never counted twice (countedEdges uniqueness)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final bom = controller.trussBomSummary;
      final countedIds = <String>{};
      for (final item in [...bom.pillarMembers, ...bom.upperMembers]) {
        expect(countedIds.contains(item.edgeId), isFalse,
            reason: 'Edge ${item.edgeId} must not be counted twice');
        countedIds.add(item.edgeId);
      }
      expect(bom.totalQuantity, equals(countedIds.length));
    });

    // ── Test 18: Deterministic Member Numbering ───────────────────────────────
    test('18. Member numbering remains deterministic and matches layout edges', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final numbering = controller.displayNumbering;
      expect(numbering.edgeNumbers.length, equals(controller.layout.edges.length));
      for (final edge in controller.layout.edges.values) {
        expect(numbering.getEdgeNumber(edge.id), isNotNull);
      }
    });

    // ── Test 19: Regression — Shared Top Node Verification ────────────────────
    test('19. Tower top node IS the authoritative perimeter node (zero gap, shared node identity)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
        includeTowerEdges: true,
      );

      final layout = controller.layout;
      final towerEdges = layout.edges.values.where((e) => e.role == TrussMemberRole.tower).toList();
      expect(towerEdges.isNotEmpty, isTrue);

      for (final towerEdge in towerEdges) {
        final topNode = layout.getNode(towerEdge.endNodeId);
        expect(topNode, isNotNull);
        expect(topNode!.elevation, equals(20.0),
            reason: 'Tower top elevation must equal main truss elevation (20 ft)');

        // Crucial check: Top node must be connected to upper perimeter edges!
        final connectedUpperEdges = layout.edges.values.where(
          (e) => e.role == TrussMemberRole.upper &&
              (e.startNodeId == topNode.id || e.endNodeId == topNode.id),
        ).toList();

        expect(connectedUpperEdges.isNotEmpty, isTrue,
            reason: 'Tower top node ${topNode.id} must be the exact same node that connects to upper truss members (ZERO GAP)');
      }
    });
  });
}
