import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';

void main() {
  test('Debug BaseTrussArchitectureGenerator for 100x100 30ft', () {
    final layout = BaseTrussArchitectureGenerator.generate(
      const BaseTrussGenerationParams(
        plotWidth: 100.0,
        plotDepth: 100.0,
        preferredPoleSpacing: 30.0,
        poleHeight: 20.0,
      ),
    );

    print('GENERATED NODES COUNT: ');
    for (final entry in layout.nodes.entries) {
      print('  Node : (, ) type= support=');
    }

    print('GENERATED EDGES COUNT: ');
    for (final entry in layout.edges.entries) {
      final sn = layout.nodes[entry.value.startNodeId]!;
      final en = layout.nodes[entry.value.endNodeId]!;
      final len = layout.getExactGeometricLengthFeet(entry.value);
      print('  Edge : from (,) to (,) len= ft');
    }
  });
}
