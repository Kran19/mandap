import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/create_center_cross_command.dart';
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

      // Check 60ft and 90ft intermediate joint nodes have support == NodeSupport.pole
      final poleNodes = layout.nodes.values.where((n) => n.support == NodeSupport.pole && n.type != NodeType.controlPoint).toList();
      // 4 corners + 8 intermediate poles (at 60ft and 90ft on all 4 sides) = 12 poles total
      expect(poleNodes.length, equals(12));

      // Specific 60ft and 90ft positions must be poles
      expect(layout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 0).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 90).abs() < 0.1 && (n.z - 0).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 100).abs() < 0.1 && (n.z - 60).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 100).abs() < 0.1 && (n.z - 90).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 60).abs() < 0.1 && (n.z - 100).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 90).abs() < 0.1 && (n.z - 100).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 0).abs() < 0.1 && (n.z - 60).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
      expect(layout.nodes.values.any((n) => (n.x - 0).abs() < 0.1 && (n.z - 90).abs() < 0.1 && n.support == NodeSupport.pole), isTrue);
    });

    test('CreateCenterCrossCommand keeps all 4 walls closed and adds 4 cross members', () {
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
      );

      final updatedLayout = command.execute(initialLayout);

      // Center node must exist as an overhead junction (no ground pole)
      final centerNode = updatedLayout.nodes.values.firstWhere((n) => (n.x - 50).abs() < 0.1 && (n.z - 50).abs() < 0.1);
      expect(centerNode.support, equals(NodeSupport.none));

      // Cross connects straight to the exact midpoint at 50ft on all 4 sides
      final northMid = updatedLayout.nodes.values.firstWhere((n) => (n.x - 50).abs() < 0.1 && (n.z - 0).abs() < 0.1);
      final eastMid = updatedLayout.nodes.values.firstWhere((n) => (n.x - 100).abs() < 0.1 && (n.z - 50).abs() < 0.1);
      final southMid = updatedLayout.nodes.values.firstWhere((n) => (n.x - 50).abs() < 0.1 && (n.z - 100).abs() < 0.1);
      final westMid = updatedLayout.nodes.values.firstWhere((n) => (n.x - 0).abs() < 0.1 && (n.z - 50).abs() < 0.1);

      // Midpoint connection nodes do NOT create new support poles
      expect(northMid.support, equals(NodeSupport.none));
      expect(eastMid.support, equals(NodeSupport.none));
      expect(southMid.support, equals(NodeSupport.none));
      expect(westMid.support, equals(NodeSupport.none));

      // 4 straight cross edges connected to center
      final centerEdges = updatedLayout.edges.values.where((e) =>
        e.startNodeId == centerNode.id || e.endNodeId == centerNode.id
      ).toList();
      expect(centerEdges.length, equals(4));

      // Total edges = 16 perimeter edges + 4 cross edges = 20 edges
      expect(updatedLayout.edges.length, equals(20));

      // Undo restores initial layout exactly
      final undone = command.undo(updatedLayout);
      expect(undone.edges.length, equals(initialLayout.edges.length));
      expect(undone.nodes.length, equals(initialLayout.nodes.length));
    });
  });
}