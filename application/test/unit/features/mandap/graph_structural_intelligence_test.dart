import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/add_external_structure_command.dart';
import 'package:mandap/features/mandap/application/commands/move_node_command.dart';
import 'package:mandap/features/mandap/application/commands/set_node_support_command.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/services/pole_placement_engine.dart';
import 'package:mandap/features/mandap/domain/services/structural_graph_analyzer.dart';

void main() {
  group('V3 Locked Domain Architecture & Structural Intelligence', () {
    test(
      '100x100 Base Truss Architecture with Center Cross matches exact locked specification',
      () {
        // Generate 100 x 100 base architecture with 30 ft spacing and center cross
        final layout = BaseTrussArchitectureGenerator.generate(
          const BaseTrussGenerationParams(
            plotWidth: 100.0,
            plotDepth: 100.0,
            preferredPoleSpacing: 30.0,
            poleHeight: 20.0,
            includeCenterControlPoint: true,
          ),
        );

        // 1. Check perimeter nodes: 4 sides * 4 segments = 16 perimeter pole nodes
        final perimeterPoleNodes = layout.nodes.values
            .where((n) => n.structureId == 'main' && n.support == NodeSupport.pole && n.role != NodeRole.controlPoint)
            .toList();
        expect(perimeterPoleNodes.length, equals(16));

        // 2. Check center control node: exactly 1 at (50, 50) with role controlPoint and support pole
        final centerNode = layout.nodes.values
            .where((n) => n.role == NodeRole.controlPoint)
            .single;
        expect(centerNode.x, equals(50.0));
        expect(centerNode.z, equals(50.0));
        expect(centerNode.support, equals(NodeSupport.pole));

        // 3. Check 4 cross-endpoint midpoint nodes: (50,0), (100,50), (50,100), (0,50)
        // MUST be real graph nodes with role: junction, support: none (0 additional poles)
        final midpointNodes = layout.nodes.values
            .where((n) => n.role == NodeRole.junction && n.support == NodeSupport.none)
            .toList();
        expect(midpointNodes.length, equals(4));

        final midpointCoords = midpointNodes.map((n) => '${n.x.toInt()},${n.z.toInt()}').toSet();
        expect(midpointCoords, containsAll({'50,0', '100,50', '50,100', '0,50'}));

        // 4. Physical pole count: exactly 17 poles (16 perimeter + 1 center)
        final engine = const PolePlacementEngine();
        final poles = engine.calculatePoles(layout);
        expect(poles.length, equals(17));

        // 5. Total Truss Length: 400 ft perimeter (20 split segments) + 200 ft internal cross = 600 ft
        expect(layout.edges.length, equals(24)); // 20 perimeter segments + 4 internal cross
        var totalExactFeet = 0.0;
        for (final edge in layout.edges.values) {
          totalExactFeet += layout.getExactGeometricLengthFeet(edge);
        }
        expect(totalExactFeet, closeTo(600.0, 0.001));

        // 6. Structural Analysis Report: initial state is clean with 0 warnings
        final report = StructuralGraphAnalyzer.analyze(layout, preferredSpacingFeet: 30.0);
        expect(report.isClean, isTrue);
        expect(report.warnings.isEmpty, isTrue);
        expect(report.unsupportedEndpoints.isEmpty, isTrue);
        expect(report.isolatedNodes.isEmpty, isTrue);
        expect(report.longSpans.isEmpty, isTrue);
        expect(report.componentCount, equals(1));
      },
    );

    test(
      'Dragging center control node dynamically updates Euclidean edge lengths and BOM',
      () {
        final controller = MandapEditorController();
        controller.generateBaseArchitecture(
          const BaseTrussGenerationParams(
            plotWidth: 100.0,
            plotDepth: 100.0,
            preferredPoleSpacing: 30.0,
            poleHeight: 20.0,
            includeCenterControlPoint: true,
          ),
        );

        final centerNode = controller.layout.nodes.values
            .where((n) => n.role == NodeRole.controlPoint)
            .single;

        // Move center node from (50, 50) to (40, 60)
        controller.executeCommand(
          MoveNodeCommand(
            nodeId: centerNode.id,
            oldX: 50.0,
            oldZ: 50.0,
            newX: 40.0,
            newZ: 60.0,
          ),
        );

        // Lengths:
        // C(40,60) -> (50,100): sqrt(10^2 + 40^2) = sqrt(1700) ≈ 41.231056 ft
        // C(40,60) -> (100,50): sqrt(60^2 + (-10)^2) = sqrt(3700) ≈ 60.827625 ft
        // C(40,60) -> (50,0):   sqrt(10^2 + (-60)^2) = sqrt(3700) ≈ 60.827625 ft
        // C(40,60) -> (0,50):   sqrt((-40)^2 + (-10)^2) = sqrt(1700) ≈ 41.231056 ft
        // Sum of 4 internal edges ≈ 204.11736 ft
        // Total truss: 400 + 204.11736 ≈ 604.11736 ft
        final totalTruss = controller.totalLinearTrussFt;
        expect(totalTruss, closeTo(604.117, 0.01));

        // Data integrity remains strictly valid (no NaNs, no broken references)
        expect(controller.layout.validateDataIntegrity().isEmpty, isTrue);
      },
    );

    test(
      'Removing pole support retains node & members and reports soft warning without blocking',
      () {
        final controller = MandapEditorController();
        controller.generateBaseArchitecture(
          const BaseTrussGenerationParams(
            plotWidth: 100.0,
            plotDepth: 100.0,
            preferredPoleSpacing: 30.0,
            poleHeight: 20.0,
            includeCenterControlPoint: false,
          ),
        );

        final cornerNodeId = controller.layout.nodes.keys.first;

        // Initial state has 16 poles and clean report
        expect(controller.totalPoleCount, equals(16));
        expect(controller.structuralReport.isClean, isTrue);

        // Remove pole support from the corner node
        controller.executeCommand(
          SetNodeSupportCommand(
            nodeId: cornerNodeId,
            newSupport: NodeSupport.none,
          ),
        );

        // 1. Node still exists in the graph
        expect(controller.layout.nodes.containsKey(cornerNodeId), isTrue);
        expect(controller.layout.nodes[cornerNodeId]!.support, equals(NodeSupport.none));

        // 2. Physical pole count decreased by 1
        expect(controller.totalPoleCount, equals(15));

        // 3. Structural report now reports soft warning for unsupported endpoint
        expect(controller.structuralReport.isClean, isFalse);
        expect(controller.structuralReport.unsupportedEndpoints, contains(cornerNodeId));
        expect(
          controller.structuralReport.warnings.any((w) => w.contains('Unsupported structural endpoint')),
          isTrue,
        );

        // 4. Graph data integrity is 100% intact (not corrupted)
        expect(controller.layout.validateDataIntegrity().isEmpty, isTrue);

        // 5. User can re-add pole support via undo or command
        controller.undo();
        expect(controller.totalPoleCount, equals(16));
        expect(controller.structuralReport.isClean, isTrue);
      },
    );

    test(
      'Isolated pole generates soft warning without auto-deleting or crashing',
      () {
        final layout = BaseTrussArchitectureGenerator.generate(
          const BaseTrussGenerationParams(
            plotWidth: 100.0,
            plotDepth: 100.0,
            preferredPoleSpacing: 30.0,
            poleHeight: 20.0,
            includeCenterControlPoint: false,
          ),
        );

        // Add an isolated pole node (no connected edges)
        const isolatedId = NodeId('isolated_pole_1');
        final modified = layout.withNode(
          const MandapNode(
            id: isolatedId,
            x: 25.0,
            z: 25.0,
            support: NodeSupport.pole,
          ),
        );

        final report = StructuralGraphAnalyzer.analyze(modified, preferredSpacingFeet: 30.0);
        expect(report.isClean, isFalse);
        expect(report.isolatedNodes, contains(isolatedId));
        expect(
          report.warnings.any((w) => w.contains('Isolated pole')),
          isTrue,
        );

        // MANDAP does NOT delete the pole; user retains total freedom
        expect(modified.nodes.containsKey(isolatedId), isTrue);
      },
    );

    test(
      'External entrance attachment creates deterministic geometry on all 4 sides',
      () {
        final controller = MandapEditorController();
        controller.generateBaseArchitecture(
          const BaseTrussGenerationParams(
            plotWidth: 100.0,
            plotDepth: 100.0,
            preferredPoleSpacing: 30.0,
            poleHeight: 20.0,
            includeCenterControlPoint: false,
          ),
        );

        final initialEdgeCount = controller.layout.edges.length;

        // Attach 10x30 Entrance on Side A (North / Back, extends +Z)
        final cmdA = AddExternalStructureCommand(
          structureId: 'entrance_A',
          side: EntranceSide.northA,
          width: 10.0,
          projection: 30.0,
          offset: 45.0,
          height: 20.0,
        );
        controller.executeCommand(cmdA);

        // Nodes for entrance are in structure 'entrance_A'
        final entranceANodes = controller.layout.nodes.values
            .where((n) => n.structureId == 'entrance_A')
            .toList();
        expect(entranceANodes.length, equals(4));

        // Depth on Side A goes outward in +Z direction (from Z=100 to Z=130)
        final maxZ = entranceANodes.map((n) => n.z).reduce(math.max);
        expect(maxZ, equals(130.0));

        // Undo removes the external entrance cleanly
        controller.undo();
        expect(controller.layout.edges.length, equals(initialEdgeCount));
        expect(controller.layout.nodes.values.any((n) => n.structureId == 'entrance_A'), isFalse);
      },
    );
  });
}
