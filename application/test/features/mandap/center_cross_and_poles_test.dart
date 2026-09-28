import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/create_center_cross_command.dart';
import 'package:mandap/features/mandap/application/commands/adjust_center_position_command.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';

void main() {
  group('BaseTrussArchitectureGenerator & CreateCenterCrossCommand Tests', () {
    test('Initial 100x100 with 30ft truss has poles at 60ft nodes and corners', () {
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100,
          plotDepth: 100,
          preferredPoleSpacing: 30,
        ),
      );

      // Check corner nodes have support == NodeSupport.pole
      final cornerNodes = layout.nodes.values.where((n) => n.type == NodeType.corner).toList();
      expect(cornerNodes.length, equals(4));
      for (final c in cornerNodes) {
        expect(c.support, equals(NodeSupport.pole));
      }

      // Check 30ft, 60ft, and 90ft intermediate joint nodes have support == NodeSupport.pole
      final poleNodes = layout.nodes.values.where((n) => n.support == NodeSupport.pole && n.type != NodeType.controlPoint).toList();
      // 4 corners + 12 intermediate poles (at 30ft, 60ft, and 90ft on all 4 sides) = 16 poles total
      expect(poleNodes.length, equals(16));

      // Specific 30ft, 60ft and 90ft positions must be poles
      expect(layout.nodes.values.any((n) => (n.x - 30).abs() < 0.1 && (n.z - 0).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 0).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 90).abs() < 0.1 && (n.z - 0).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 100).abs() < 0.1 && (n.z - 30).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 100).abs() < 0.1 && (n.z - 60).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 100).abs() < 0.1 && (n.z - 90).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 30).abs() < 0.1 && (n.z - 100).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 100).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 90).abs() < 0.1 && (n.z - 100).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 0).abs() < 0.1 && (n.z - 30).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 0).abs() < 0.1 && (n.z - 60).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 0).abs() < 0.1 && (n.z - 90).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
    });

    test('CreateCenterCrossCommand allows 40ft without intermediate pole and places pole when > 40ft', () {
      final initialLayout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100,
          plotDepth: 100,
          preferredPoleSpacing: 30,
        ),
      );

      final command = CreateCenterCrossCommand(
        plotWidth: 100,
        plotDepth: 100,
        elevation: 20,
        preferredPoleSpacing: 30,
      );

      final updatedLayout = command.execute(initialLayout);

      // Center node must exist as a junction with a center ground support pole
      final centerNode = updatedLayout.nodes.values.firstWhere((n) => (n.x - 60).abs() < 0.1 && (n.z - 60).abs() < 0.1);
      expect(centerNode.support, equals(NodeSupport.pole));

      // Intermediate support poles on 60ft arms (at (60, 30) and (30, 60))
      expect(updatedLayout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 30).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(updatedLayout.nodes.values.any((n) => (n.x - 30).abs() < 0.1 && (n.z - 60).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);

      // 40ft arms (East and South) do NOT have intermediate poles because 40ft is allowed
      expect(updatedLayout.nodes.values.any((n) => (n.x - 70).abs() < 0.1 && (n.z - 60).abs() < 0.1), isFalse);
      expect(updatedLayout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 70).abs() < 0.1), isFalse);

      // Total edges = 16 perimeter + 2 (North) + 2 (West) + 1 (East) + 1 (South) = 22 edges
      expect(updatedLayout.edges.length, equals(22));

      // Undo restores initial layout exactly
      final undone = command.undo(updatedLayout);
      expect(undone.edges.length, equals(initialLayout.edges.length));
      expect(undone.nodes.length, equals(initialLayout.nodes.length));
    });

    test('AdjustCenterPositionCommand recalculates poles when moved (e.g. to (62, 66))', () {
      final initialLayout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100,
          plotDepth: 100,
          preferredPoleSpacing: 30,
        ),
      );

      final createCmd = CreateCenterCrossCommand(
        plotWidth: 100,
        plotDepth: 100,
        elevation: 20,
        preferredPoleSpacing: 30,
      );
      final crossLayout = createCmd.execute(initialLayout);

      final centerNode = crossLayout.nodes.values.firstWhere((n) => (n.x - 60).abs() < 0.1 && (n.z - 60).abs() < 0.1);

      // Move center node to (62, 66)
      final adjustCmd = AdjustCenterPositionCommand(
        centerNodeId: centerNode.id,
        oldX: 60.0,
        oldZ: 60.0,
        newX: 62.0,
        newZ: 66.0,
      );

      final movedLayout = adjustCmd.execute(crossLayout);

      // Center node moved to (62, 66)
      final newCenter = movedLayout.getNode(centerNode.id);
      expect(newCenter, isNotNull);
      expect(newCenter!.x, equals(62.0));
      expect(newCenter.z, equals(66.0));

      // West arm is 62 ft > 40 ft -> has intermediate pole at (30, 66)
      expect(movedLayout.nodes.values.any((n) => (n.x - 30).abs() < 0.5 && (n.z - 66).abs() < 0.5 && n.support == NodeSupport.pole), isTrue);

      // North arm is 66 ft > 40 ft -> has intermediate pole at (62, 30)
      expect(movedLayout.nodes.values.any((n) => (n.x - 62).abs() < 0.5 && (n.z - 30).abs() < 0.5 && n.support == NodeSupport.pole), isTrue);

      // East arm is 38 ft <= 40 ft -> NO intermediate pole
      // South arm is 34 ft <= 40 ft -> NO intermediate pole
      expect(movedLayout.edges.length, equals(22));
    });

    test('100x100 with 25ft truss aligns cross-arm poles with x=25, x=75 and z=25, z=75 columns', () {
      final initialLayout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 100,
          plotDepth: 100,
          preferredPoleSpacing: 25,
        ),
      );

      final createCmd = CreateCenterCrossCommand(
        plotWidth: 100,
        plotDepth: 100,
        elevation: 20,
        preferredPoleSpacing: 25,
      );
      final crossLayout = createCmd.execute(initialLayout);

      // Center node at (50, 50)
      final centerNode = crossLayout.nodes.values.firstWhere((n) => (n.x - 50).abs() < 0.1 && (n.z - 50).abs() < 0.1);
      expect(centerNode.support, equals(NodeSupport.pole));

      // West arm from (0, 50) to (50, 50): pole must be at (25, 50), in 1 line with (25, 0) and (25, 100)
      expect(crossLayout.nodes.values.any((n) => (n.x - 25).abs() < 0.1 && (n.z - 50).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);

      // East arm from (100, 50) to (50, 50): pole must be at (75, 50), in 1 line with (75, 0) and (75, 100)
      expect(crossLayout.nodes.values.any((n) => (n.x - 75).abs() < 0.1 && (n.z - 50).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);

      // North arm from (50, 0) to (50, 50): pole must be at (50, 25), in 1 line with (0, 25) and (100, 25)
      expect(crossLayout.nodes.values.any((n) => (n.x - 50).abs() < 0.1 && (n.z - 25).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);

      // South arm from (50, 100) to (50, 50): pole must be at (50, 75), in 1 line with (0, 75) and (100, 75)
      expect(crossLayout.nodes.values.any((n) => (n.x - 50).abs() < 0.1 && (n.z - 75).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
    });
  });
}