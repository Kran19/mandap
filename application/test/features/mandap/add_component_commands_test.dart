import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/add_component_commands.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/specifications/component_specifications.dart';

void main() {
  group('Component Generators / Commands', () {
    late MandapLayout layout;

    beforeEach() {
      layout = MandapLayout(nodes: const {}, edges: const {});
    }

    test('AddTrussCommand creates a closed rectangular loop with exact 1e-9 tolerance parity', () {
      layout = MandapLayout(nodes: const {}, edges: const {});
      final spec = TrussSpecification(
        width: 10.123456789,
        depth: 20.987654321,
        height: 15.0,
        roofElevation: 15.0,
      );

      final cmd = AddTrussCommand(spec: spec);
      final newLayout = cmd.execute(layout);

      expect(newLayout.nodes.length, 4);
      expect(newLayout.edges.length, 4);

      final nodes = newLayout.nodes.values.toList();
      
      // Node 1: (0, 0)
      expect(nodes[0].x, closeTo(0.0, 1e-9));
      expect(nodes[0].z, closeTo(0.0, 1e-9));
      
      // Node 2: (w, 0)
      expect(nodes[1].x, closeTo(spec.width, 1e-9));
      expect(nodes[1].z, closeTo(0.0, 1e-9));
      
      // Node 3: (w, d)
      expect(nodes[2].x, closeTo(spec.width, 1e-9));
      expect(nodes[2].z, closeTo(spec.depth, 1e-9));
      
      // Node 4: (0, d)
      expect(nodes[3].x, closeTo(0.0, 1e-9));
      expect(nodes[3].z, closeTo(spec.depth, 1e-9));

      // All nodes have elevation e
      for (final node in nodes) {
        expect(node.elevation, closeTo(spec.roofElevation, 1e-9));
        expect(node.type, NodeType.corner);
      }

      // Check undo
      final undoneLayout = cmd.undo(newLayout);
      expect(undoneLayout.nodes, isEmpty);
      expect(undoneLayout.edges, isEmpty);
    });

    test('AddPoleCommand creates a single pole at exact coordinates', () {
      layout = MandapLayout(nodes: const {}, edges: const {});
      final spec = PoleSpecification(
        x: 5.555555555,
        z: -3.333333333,
        height: 12.0,
        diameter: 0.5,
      );

      final cmd = AddPoleCommand(spec: spec);
      final newLayout = cmd.execute(layout);

      expect(newLayout.nodes.length, 1);
      final node = newLayout.nodes.values.first;

      expect(node.type, NodeType.pole);
      expect(node.x, closeTo(spec.x, 1e-9));
      expect(node.z, closeTo(spec.z, 1e-9));
      expect(node.height, closeTo(spec.height, 1e-9));
      expect(node.width, closeTo(spec.diameter, 1e-9));
      expect(node.depth, closeTo(spec.diameter, 1e-9));

      final undoneLayout = cmd.undo(newLayout);
      expect(undoneLayout.nodes, isEmpty);
    });

    test('AddCarpetCommand creates flooring at exact coordinates', () {
      layout = MandapLayout(nodes: const {}, edges: const {});
      final spec = FlooringSpecification(
        x: 0.123456789,
        z: 0.987654321,
        width: 100.0,
        depth: 50.0,
        thickness: 0.1,
        rotation: 45.0,
      );

      final cmd = AddCarpetCommand(spec: spec);
      final newLayout = cmd.execute(layout);

      expect(newLayout.nodes.length, 1);
      final node = newLayout.nodes.values.first;

      expect(node.type, NodeType.carpet);
      expect(node.x, closeTo(spec.x, 1e-9));
      expect(node.z, closeTo(spec.z, 1e-9));
      expect(node.width, closeTo(spec.width, 1e-9));
      expect(node.depth, closeTo(spec.depth, 1e-9));
      expect(node.height, closeTo(spec.thickness, 1e-9));
      expect(node.rotation, closeTo(spec.rotation, 1e-9));

      final undoneLayout = cmd.undo(newLayout);
      expect(undoneLayout.nodes, isEmpty);
    });

    test('AddStageCommand creates stage at exact coordinates', () {
      layout = MandapLayout(nodes: const {}, edges: const {});
      final spec = StageSpecification(
        x: 12.345678901,
        z: 98.765432109,
        width: 40.0,
        depth: 30.0,
        height: 3.5,
        rotation: 90.0,
      );

      final cmd = AddStageCommand(spec: spec);
      final newLayout = cmd.execute(layout);

      expect(newLayout.nodes.length, 1);
      final node = newLayout.nodes.values.first;

      expect(node.type, NodeType.stage);
      expect(node.x, closeTo(spec.x, 1e-9));
      expect(node.z, closeTo(spec.z, 1e-9));
      expect(node.width, closeTo(spec.width, 1e-9));
      expect(node.depth, closeTo(spec.depth, 1e-9));
      expect(node.height, closeTo(spec.height, 1e-9));
      expect(node.rotation, closeTo(spec.rotation, 1e-9));

      final undoneLayout = cmd.undo(newLayout);
      expect(undoneLayout.nodes, isEmpty);
    });
  });
}
