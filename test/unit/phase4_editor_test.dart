import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/add_edge_command.dart';
import 'package:mandap/features/mandap/application/commands/add_node_command.dart';
import 'package:mandap/features/mandap/application/commands/delete_edge_command.dart';
import 'package:mandap/features/mandap/application/commands/delete_node_command.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_preset.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';
import 'package:mandap/features/mandap/presentation/viewport_transform.dart';

void main() {
  // ── MandapLayout mutation helpers ──────────────────────────────────────────

  group('MandapLayout mutation helpers', () {
    late MandapLayout base;

    setUp(() {
      base = MandapPreset.rectangle30x20().createLayout();
    });

    test('withNode adds a new node without modifying original', () {
      final newNode = MandapNode(id: const NodeId('extra'), x: 100.0, z: 100.0);
      final updated = base.withNode(newNode);

      expect(updated.nodes.length, base.nodes.length + 1);
      expect(updated.getNode(const NodeId('extra')), isNotNull);
      expect(base.nodes.containsKey(const NodeId('extra')), isFalse);
    });

    test('withEdge adds a new edge without modifying original', () {
      // Add a third node first so the edge reference is valid
      final n1 = const NodeId('n1');
      final n2 = const NodeId('n2');
      final newEdgeId = const EdgeId('eExtra');
      final newEdge = MandapEdge(id: newEdgeId, startNodeId: n1, endNodeId: n2);

      final updated = base.withEdge(newEdge);
      expect(updated.edges.length, base.edges.length + 1);
      expect(base.edges.containsKey(newEdgeId), isFalse);
    });

    test('withoutNode removes node without modifying original', () {
      final nodeToRemove = base.nodes.keys.first;
      final updated = base.withoutNode(nodeToRemove);

      expect(updated.nodes.length, base.nodes.length - 1);
      expect(updated.getNode(nodeToRemove), isNull);
      expect(base.getNode(nodeToRemove), isNotNull);
    });

    test('withoutEdge removes edge without modifying original', () {
      final edgeToRemove = base.edges.keys.first;
      final updated = base.withoutEdge(edgeToRemove);

      expect(updated.edges.length, base.edges.length - 1);
      expect(updated.getEdge(edgeToRemove), isNull);
      expect(base.getEdge(edgeToRemove), isNotNull);
    });

    test('withoutNodeAndConnectedEdges removes node + all its edges', () {
      final n1 = const NodeId('n1');
      // n1 is connected to e1 (n1→n2) and e4 (n4→n1) in a rectangle
      final updated = base.withoutNodeAndConnectedEdges(n1);

      expect(updated.getNode(n1), isNull);
      // All edges touching n1 must be gone
      for (final edge in updated.edges.values) {
        expect(edge.startNodeId == n1 || edge.endNodeId == n1, isFalse);
      }
    });
  });

  // ── AddNodeCommand ─────────────────────────────────────────────────────────

  group('AddNodeCommand', () {
    test('execute adds node; undo removes it', () {
      final layout = MandapPreset.rectangle30x20().createLayout();
      final node = MandapNode(id: const NodeId('nTest'), x: 50, z: 50);
      final cmd = AddNodeCommand(node: node);

      final after = cmd.execute(layout);
      expect(after.nodes.length, layout.nodes.length + 1);

      final restored = cmd.undo(after);
      expect(restored.nodes.length, layout.nodes.length);
      expect(restored.getNode(const NodeId('nTest')), isNull);
    });
  });

  // ── AddEdgeCommand ─────────────────────────────────────────────────────────

  group('AddEdgeCommand', () {
    test('execute adds edge; undo removes it', () {
      final layout = MandapPreset.rectangle30x20().createLayout();
      final n1 = const NodeId('n1');
      final n3 = const NodeId('n3');
      final edgeId = const EdgeId('eDiag');
      final cmd = AddEdgeCommand(
        edgeId: edgeId,
        startNodeId: n1,
        endNodeId: n3,
      );

      final after = cmd.execute(layout);
      expect(after.edges.length, layout.edges.length + 1);

      final restored = cmd.undo(after);
      expect(restored.edges.length, layout.edges.length);
      expect(restored.getEdge(edgeId), isNull);
    });
  });

  // ── DeleteEdgeCommand ──────────────────────────────────────────────────────

  group('DeleteEdgeCommand', () {
    test('execute removes edge; undo restores it exactly', () {
      final layout = MandapPreset.rectangle30x20().createLayout();
      final edgeToDelete = layout.edges.values.first;

      final cmd = DeleteEdgeCommand(
        edgeId: edgeToDelete.id,
        snapshot: edgeToDelete,
      );

      final after = cmd.execute(layout);
      expect(after.edges.length, layout.edges.length - 1);
      expect(after.getEdge(edgeToDelete.id), isNull);

      final restored = cmd.undo(after);
      expect(restored.edges.length, layout.edges.length);
      expect(restored.getEdge(edgeToDelete.id), equals(edgeToDelete));
    });
  });

  // ── DeleteNodeCommand ──────────────────────────────────────────────────────

  group('DeleteNodeCommand', () {
    test('execute removes node + connected edges; undo restores all', () {
      final layout = MandapPreset.rectangle30x20().createLayout();
      final nodeId = const NodeId('n1');
      final node = layout.getNode(nodeId)!;
      final connected = layout.edges.values
          .where((e) => e.startNodeId == nodeId || e.endNodeId == nodeId)
          .toList();

      final cmd = DeleteNodeCommand(
        nodeId: nodeId,
        nodeSnapshot: node,
        connectedEdgeSnapshots: connected,
      );

      final after = cmd.execute(layout);
      expect(after.getNode(nodeId), isNull);
      for (final e in connected) {
        expect(after.getEdge(e.id), isNull);
      }

      final restored = cmd.undo(after);
      expect(restored.getNode(nodeId), equals(node));
      for (final e in connected) {
        expect(restored.getEdge(e.id), isNotNull);
      }
    });
  });

  // ── MandapEditorController Phase 4 operations ──────────────────────────────

  group('MandapEditorController Phase 4', () {
    late MandapEditorController ctrl;

    setUp(() {
      ctrl = MandapEditorController();
    });

    tearDown(() {
      ctrl.dispose();
    });

    test('addNode increases node count by 1', () {
      final before = ctrl.layout.nodes.length;
      ctrl.addNode(x: 10, z: 10);
      expect(ctrl.layout.nodes.length, before + 1);
    });

    test('addEdge increases edge count by 1', () {
      // Add two isolated nodes to connect
      final id1 = ctrl.addNode(x: 0, z: 0);
      final id2 = ctrl.addNode(x: 10, z: 0);
      final edgesBefore = ctrl.layout.edges.length;
      final success = ctrl.addEdge(startNodeId: id1, endNodeId: id2);
      expect(success, isTrue);
      expect(ctrl.layout.edges.length, edgesBefore + 1);
    });

    test('addEdge returns false if a node does not exist', () {
      final success = ctrl.addEdge(
        startNodeId: const NodeId('ghost'),
        endNodeId: const NodeId('n1'),
      );
      expect(success, isFalse);
    });

    test('deleteNode removes node and connected edges', () {
      final nodeId = const NodeId('n1');
      final connectedBefore = ctrl.layout.edges.values
          .where((e) => e.startNodeId == nodeId || e.endNodeId == nodeId)
          .length;
      final nodesBefore = ctrl.layout.nodes.length;
      final edgesBefore = ctrl.layout.edges.length;

      ctrl.deleteNode(nodeId);

      expect(ctrl.layout.getNode(nodeId), isNull);
      expect(ctrl.layout.nodes.length, nodesBefore - 1);
      expect(ctrl.layout.edges.length, edgesBefore - connectedBefore);
    });

    test('deleteEdge removes only the edge', () {
      final edgeId = ctrl.layout.edges.keys.first;
      final edgesBefore = ctrl.layout.edges.length;
      final nodesBefore = ctrl.layout.nodes.length;

      ctrl.deleteEdge(edgeId);

      expect(ctrl.layout.edges.length, edgesBefore - 1);
      expect(ctrl.layout.nodes.length, nodesBefore); // nodes unchanged
    });

    test('undo/redo works across addNode + addEdge sequence', () {
      final nodesBefore = ctrl.layout.nodes.length;
      final edgesBefore = ctrl.layout.edges.length;

      // Use axis-aligned nodes so the edge length is a clean 0.5 ft multiple.
      // (100, 0) → (70, 0) = 30 ft horizontal edge.
      final id1 = ctrl.addNode(x: 100, z: 0);
      final id2 = ctrl.addNode(x: 70, z: 0);
      ctrl.addEdge(startNodeId: id1, endNodeId: id2);

      expect(ctrl.layout.nodes.length, nodesBefore + 2);
      expect(ctrl.layout.edges.length, edgesBefore + 1);

      ctrl.undo(); // undo addEdge
      expect(ctrl.layout.edges.length, edgesBefore);

      ctrl.undo(); // undo addNode(id2)
      expect(ctrl.layout.nodes.length, nodesBefore + 1);

      ctrl.undo(); // undo addNode(id1)
      expect(ctrl.layout.nodes.length, nodesBefore);
      expect(ctrl.layout.edges.length, edgesBefore);

      ctrl.redo(); // redo addNode(id1)
      ctrl.redo(); // redo addNode(id2)
      ctrl.redo(); // redo addEdge
      expect(ctrl.layout.nodes.length, nodesBefore + 2);
      expect(ctrl.layout.edges.length, edgesBefore + 1);
    });

    test('setMode clears pending state and selection', () {
      ctrl.selectNode(const NodeId('n1'));
      ctrl.setMode(EditorMode.addNode);

      expect(ctrl.mode, EditorMode.addNode);
      expect(ctrl.selectedNodeId, isNull);
      expect(ctrl.pendingEdgeStartNodeId, isNull);
    });

    test('handleAddEdgeTap continuous polyline chain drawing workflow', () {
      ctrl.setMode(EditorMode.addEdge);

      final n1 = const NodeId('n1');
      final n2 = const NodeId('n2');
      final n3 = const NodeId('n3');
      final edgesBefore = ctrl.layout.edges.length;

      // Tap n1 (start node of chain)
      ctrl.handleAddEdgeTap(n1);
      expect(ctrl.pendingEdgeStartNodeId, n1);

      // Tap n2 (creates edge n1->n2 and pending becomes n2)
      ctrl.handleAddEdgeTap(n2);
      expect(ctrl.pendingEdgeStartNodeId, n2);
      expect(ctrl.layout.edges.length, edgesBefore + 1);

      // Tap n3 (creates edge n2->n3 and pending becomes n3)
      ctrl.handleAddEdgeTap(n3);
      expect(ctrl.pendingEdgeStartNodeId, n3);
      expect(ctrl.layout.edges.length, edgesBefore + 2);

      // Tap n3 again (cancels/completes chain)
      ctrl.handleAddEdgeTap(n3);
      expect(ctrl.pendingEdgeStartNodeId, isNull);
    });

    test('preset to custom state transitions cleanly', () {
      expect(ctrl.isCustomLayout, isFalse);

      ctrl.addNode(x: 10, z: 10);
      expect(ctrl.isCustomLayout, isTrue);

      ctrl.loadPreset(MandapPreset.rectangle40x30());
      expect(ctrl.isCustomLayout, isFalse);
    });

    test(
      'direct dimension editing resizes edge and recalculates BOM and supports undo',
      () {
        final edge = ctrl.layout.edges.values.first; // e1: n1(0,0) -> n2(40,0)
        final originalLen = ctrl.layout.getEdgeLength(edge);
        expect(originalLen.feet, 40.0);

        // Resize e1 from 40 ft to 37.5 ft
        ctrl.resizeEdge(
          edgeId: edge.id,
          movingNodeId: edge.endNodeId,
          newX: 37.5,
          newZ: 0.0,
        );

        final newLen = ctrl.layout.getEdgeLength(ctrl.layout.getEdge(edge.id)!);
        expect(newLen.feet, 37.5);
        expect(ctrl.result.edgeSolutions[edge.id]!.targetLength.feet, 37.5);

        // Undo restores original 40 ft
        ctrl.undo();
        final restoredLen = ctrl.layout.getEdgeLength(
          ctrl.layout.getEdge(edge.id)!,
        );
        expect(restoredLen.feet, 40.0);
      },
    );
  });

  // ── Graph Validation Tests ──────────────────────────────────────────────────

  group('Graph Validation (Crossing Edges & Connectivity)', () {
    test('detects crossing edges in 2D space', () {
      final n1 = MandapNode(id: const NodeId('n1'), x: 0, z: 0);
      final n2 = MandapNode(id: const NodeId('n2'), x: 20, z: 20);
      final n3 = MandapNode(id: const NodeId('n3'), x: 0, z: 20);
      final n4 = MandapNode(id: const NodeId('n4'), x: 20, z: 0);

      final e1 = MandapEdge(
        id: const EdgeId('e1'),
        startNodeId: n1.id,
        endNodeId: n2.id,
      );
      final e2 = MandapEdge(
        id: const EdgeId('e2'),
        startNodeId: n3.id,
        endNodeId: n4.id,
      );

      final layout = MandapLayout(
        nodes: {n1.id: n1, n2.id: n2, n3.id: n3, n4.id: n4},
        edges: {e1.id: e1, e2.id: e2},
      );

      final issues = layout.validate();
      expect(issues.any((i) => i.contains('cross each other')), isTrue);
    });

    test('detects disconnected graph components', () {
      final n1 = MandapNode(id: const NodeId('n1'), x: 0, z: 0);
      final n2 = MandapNode(id: const NodeId('n2'), x: 10, z: 0);
      final n3 = MandapNode(id: const NodeId('n3'), x: 50, z: 50);
      final n4 = MandapNode(id: const NodeId('n4'), x: 60, z: 50);

      final e1 = MandapEdge(
        id: const EdgeId('e1'),
        startNodeId: n1.id,
        endNodeId: n2.id,
      );
      final e2 = MandapEdge(
        id: const EdgeId('e2'),
        startNodeId: n3.id,
        endNodeId: n4.id,
      );

      final layout = MandapLayout(
        nodes: {n1.id: n1, n2.id: n2, n3.id: n3, n4.id: n4},
        edges: {e1.id: e1, e2.id: e2},
      );

      final issues = layout.validate();
      expect(issues.any((i) => i.contains('disconnected')), isTrue);
    });
  });

  // ── Diagonal Edge Geometry Tests ───────────────────────────────────────────

  group('Diagonal Edge Geometry', () {
    test(
      'diagonal edge calculates Euclidean distance and reports warning without crashing',
      () {
        final n1 = MandapNode(id: const NodeId('n1'), x: 0, z: 0);
        final n2 = MandapNode(id: const NodeId('n2'), x: 10, z: 10);
        final e1 = MandapEdge(
          id: const EdgeId('e1'),
          startNodeId: n1.id,
          endNodeId: n2.id,
        );

        final layout = MandapLayout(
          nodes: {n1.id: n1, n2.id: n2},
          edges: {e1.id: e1},
        );

        final engine = const MandapCalculationEngine();
        final catalog = TrussCatalog.sample1To20Ft();
        final inventory = TrussInventory.sample(catalog);

        final result = engine.calculate(
          layout: layout,
          catalog: catalog,
          inventory: inventory,
        );

        // Verify app does not crash and warning is added for non-0.5ft diagonal edge
        expect(
          result.warnings.any((w) => w.contains('diagonal length')),
          isTrue,
        );
      },
    );
  });

  // ── ViewportTransform ──────────────────────────────────────────────────────

  group('ViewportTransform', () {
    const transform = ViewportTransform(scale: 10, panX: 50, panY: 50);

    test('worldToScreen round-trips correctly', () {
      const wx = 12.5;
      const wz = 7.0;
      final screen = transform.worldToScreen(wx, wz);
      final world = transform.screenToWorld(screen);
      expect(world.x, closeTo(wx, 0.001));
      expect(world.z, closeTo(wz, 0.001));
    });

    test('snapToGrid snaps to 0.5 ft increments', () {
      expect(transform.snapToGrid(3.2, 7.8).x, closeTo(3.0, 0.001));
      expect(transform.snapToGrid(3.2, 7.8).z, closeTo(8.0, 0.001));
      expect(transform.snapToGrid(2.76, 0.1).x, closeTo(3.0, 0.001));
      expect(transform.snapToGrid(2.76, 0.1).z, closeTo(0.0, 0.001));
    });

    test('hitTestNode detects point within radius', () {
      // Node at world (0,0) → screen (50,50) with scale=10
      expect(transform.hitTestNode(const Offset(50, 50), 0, 0), isTrue);
      expect(transform.hitTestNode(const Offset(70, 70), 0, 0), isFalse);
    });

    test('hitTestEdge detects point on segment', () {
      // Edge from world (0,0)→(10,0): screen from (50,50)→(150,50)
      // Midpoint at screen (100,50) should hit
      expect(transform.hitTestEdge(const Offset(100, 50), 0, 0, 10, 0), isTrue);
      // Point far off: screen (100, 100) should miss
      expect(
        transform.hitTestEdge(const Offset(100, 100), 0, 0, 10, 0),
        isFalse,
      );
    });

    test('pan shifts panX and panY', () {
      final panned = transform.pan(20, -10);
      expect(panned.panX, 70);
      expect(panned.panY, 40);
      expect(panned.scale, transform.scale);
    });

    test('zoom clamps to min/max scale', () {
      final tooSmall = transform.zoom(0.00001, const Offset(0, 0));
      expect(tooSmall.scale, ViewportTransform.minScale);

      final tooBig = transform.zoom(1000, const Offset(0, 0));
      expect(tooBig.scale, ViewportTransform.maxScale);
    });
  });
}
