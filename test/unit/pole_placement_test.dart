import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/services/pole_placement_engine.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';

void main() {
  group('PolePlacementEngine Boundary & Invariant Tests', () {
    const engine = PolePlacementEngine(maxSpanFeet: 30.0);

    MandapLayout createSingleEdgeLayout(double lengthFeet) {
      final n1 = const NodeId('n1');
      final n2 = const NodeId('n2');
      final e1 = const EdgeId('e1');

      return MandapLayout(
        nodes: {
          n1: MandapNode(id: n1, x: 0.0, z: 0.0, type: NodeType.corner),
          n2: MandapNode(id: n2, x: lengthFeet, z: 0.0, type: NodeType.corner),
        },
        edges: {e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2)},
      );
    }

    test('30 ft edge requires 0 intermediate poles', () {
      final layout = createSingleEdgeLayout(30.0);
      final poles = engine.calculatePoles(layout);

      final cornerPoles = poles
          .where((p) => p.reason == PoleReason.corner)
          .length;
      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .length;

      expect(cornerPoles, equals(2));
      expect(generatedPoles, equals(0));
    });

    test('30.5 ft edge requires 1 intermediate pole', () {
      final layout = createSingleEdgeLayout(30.5);
      final poles = engine.calculatePoles(layout);

      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .toList();

      expect(generatedPoles.length, equals(1));
      expect(generatedPoles[0].x, closeTo(15.25, 1e-4));
    });

    test('60 ft edge requires 1 intermediate pole', () {
      final layout = createSingleEdgeLayout(60.0);
      final poles = engine.calculatePoles(layout);

      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .toList();

      expect(generatedPoles.length, equals(1));
      expect(generatedPoles[0].x, closeTo(30.0, 1e-4));
    });

    test('60.5 ft edge requires 2 intermediate poles', () {
      final layout = createSingleEdgeLayout(60.5);
      final poles = engine.calculatePoles(layout);

      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .toList();

      expect(generatedPoles.length, equals(2));
    });

    test('70 ft edge requires 2 intermediate poles', () {
      final layout = createSingleEdgeLayout(70.0);
      final poles = engine.calculatePoles(layout);

      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .toList();

      expect(generatedPoles.length, equals(2));
    });

    test('INVARIANT: Every generated span is <= 30 ft', () {
      final testLengths = [30.0, 30.5, 45.0, 60.0, 60.5, 70.0, 100.0, 150.0];

      for (final len in testLengths) {
        final layout = createSingleEdgeLayout(len);
        final poles = engine.calculatePoles(layout);

        // Extract x coordinates of all poles (corners + generated) sorted
        final xCoords = poles.map((p) => p.x).toList()..sort();

        // Verify span between every consecutive pair of poles
        for (var i = 0; i < xCoords.length - 1; i++) {
          final span = xCoords[i + 1] - xCoords[i];
          expect(
            span <= 30.0 + 1e-6,
            isTrue,
            reason: 'Span $span ft exceeds 30 ft max limit for length $len ft',
          );
        }
      }
    });

    test('40 ft x 30 ft Rectangle layout generates correct poles', () {
      final layout = MandapLayout.rectangle(
        width: Length.fromFeet(40.0),
        length: Length.fromFeet(30.0),
      );

      final poles = engine.calculatePoles(layout);

      final cornerPoles = poles
          .where((p) => p.reason == PoleReason.corner)
          .length;
      final generatedPoles = poles
          .where((p) => p.reason == PoleReason.generatedMaxSpan)
          .length;

      // 4 corners, 2 40 ft edges each get 1 generated pole, 2 30 ft edges get 0 generated poles
      expect(cornerPoles, equals(4));
      expect(generatedPoles, equals(2));
      expect(poles.length, equals(6));
    });
  });
}
