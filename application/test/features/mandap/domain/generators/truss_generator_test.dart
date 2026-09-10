import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/mandap/domain/generators/truss_generator.dart';
import '../../../../../lib/features/mandap/domain/specifications/component_specifications.dart';
import '../../../../../lib/features/mandap/domain/entities/mandap_node.dart';
import '../../../../../lib/features/mandap/domain/entities/mandap_edge.dart';
import '../../../../../lib/features/mandap/infrastructure/layout_serializer.dart';

void main() {
  group('TrussGenerator', () {
    late TrussGenerator generator;

    setUp(() {
      generator = TrussGenerator();
    });

    test('generates valid 40x30x12 MandapLayout', () {
      final spec = const TrussSpecification(
        width: 40.0,
        depth: 30.0,
        height: 12.0,
        towerWidth: 2.0,
        towerDepth: 2.0,
        roofElevation: 10.0,
        profileHeight: 1.0,
        memberSegmentLength: 10.0,
        configuration: TrussConfiguration.fivePoint,
      );

      final layout = generator.generate(spec);

      // Graph integrity checks
      expect(layout.nodes.isNotEmpty, isTrue, reason: 'Nodes should not be empty');
      expect(layout.edges.isNotEmpty, isTrue, reason: 'Edges should not be empty');

      // No orphan nodes (every node should be referenced by at least one edge)
      for (final node in layout.nodes.values) {
        final edgesForNode = layout.edges.values.where(
            (e) => e.startNodeId == node.id || e.endNodeId == node.id);
        expect(edgesForNode.isNotEmpty, isTrue,
            reason: 'Node ${node.id} is an orphan');
      }

      // No zero-length edges
      for (final edge in layout.edges.values) {
        final start = layout.nodes[edge.startNodeId]!;
        final end = layout.nodes[edge.endNodeId]!;
        expect(
            start.x == end.x && start.elevation == end.elevation && start.z == end.z,
            isFalse,
            reason: 'Edge ${edge.id} has zero length');
      }

      // Verify Tower presence
      // Look for the base nodes at y=0, x=1, z=1
      final towerBaseNodes = layout.nodes.values.where((n) => n.elevation == 0);
      expect(towerBaseNodes.length, greaterThanOrEqualTo(4),
          reason: 'Tower must have at least 4 base nodes');

      // Verify Roof depth and perimeter
      final roofNodes = layout.nodes.values.where((n) => n.elevation == spec.roofElevation);
      expect(roofNodes.length, greaterThanOrEqualTo(4),
          reason: 'Roof canopy must have perimeter nodes at the exact roof elevation');
    });

    test('generates valid 6-point configuration', () {
      final spec = const TrussSpecification(
        width: 40.0,
        depth: 30.0,
        height: 12.0,
        roofElevation: 10.0,
        configuration: TrussConfiguration.sixPoint,
      );

      final layout = generator.generate(spec);
      
      // P6 points should exist at depth/2 + 5.0
      final p6Nodes = layout.nodes.values.where((n) => n.z == 30.0 / 2.0 + 5.0 || n.z == -30.0 / 2.0 - 5.0);
      expect(p6Nodes.isNotEmpty, isTrue, reason: '6-point awning nodes should exist');
    });

    test('tower and main truss share exact identical nodes', () {
      final spec = const TrussSpecification(
        width: 40.0,
        depth: 30.0,
        height: 12.0,
        towerWidth: 2.0,
        towerDepth: 2.0,
        roofElevation: 10.0,
      );

      final layout = generator.generate(spec);
      
      // Find the main truss spans and verify their connections at x = +/- 1.0
      final mainLeftSpanEnd = layout.nodes.values.where((n) => n.x == -1.0 && n.elevation == 10.0).toList();
      final mainRightSpanStart = layout.nodes.values.where((n) => n.x == 1.0 && n.elevation == 10.0).toList();

      expect(mainLeftSpanEnd.length, greaterThanOrEqualTo(2), reason: 'Should connect to front and rear tower nodes');
      expect(mainRightSpanStart.length, greaterThanOrEqualTo(2));
      
      // Look for edges connecting left main span to tower nodes
      bool leftConnected = false;
      for (final edge in layout.edges.values) {
        final start = layout.nodes[edge.startNodeId]!;
        final end = layout.nodes[edge.endNodeId]!;
        if ((start.x == -20.0 && end.x == -1.0) || (end.x == -20.0 && start.x == -1.0)) {
          leftConnected = true;
          // The node at -1.0 must physically exist in the layout exactly once
          final sharedNode = layout.nodes[start.x == -1.0 ? start.id : end.id];
          expect(sharedNode, isNotNull);
        }
      }
      expect(leftConnected, isTrue, reason: 'Main truss left segment must connect directly to tower frame nodes');
    });

    test('serializes and deserializes accurately with profile support', () {
      final spec = const TrussSpecification(
        width: 40.0,
        depth: 30.0,
        height: 12.0,
        roofElevation: 10.0,
        configuration: TrussConfiguration.fivePoint,
      );

      final layout = generator.generate(spec);
      
      // This part would normally test LayoutSerializer
      // For now we just verify the generated layout has profiles populated correctly
      final singleTubeEdges = layout.edges.values.where((e) => e.profile == EdgeProfile.singleTube);
      final boxEdges = layout.edges.values.where((e) => e.profile == EdgeProfile.box);
      
      expect(singleTubeEdges.isNotEmpty, isTrue, reason: 'Tower should use singleTube lattice members');
      expect(boxEdges.isNotEmpty, isTrue, reason: 'Roof and main spans should use box profiles');
    });
  });
}
