import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('MandapLayout & End-to-End Engine Tests', () {
    final catalog = TrussCatalog.sample1To20Ft();
    final inventory = TrussInventory.sample(catalog, defaultQty: 50);
    const engine = MandapCalculationEngine();

    test('40 ft x 30 ft Rectangle Fixture end-to-end calculation', () {
      final layout = MandapLayout.rectangle(
        width: Length.fromFeet(40.0),
        length: Length.fromFeet(30.0),
      );

      final result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );

      expect(result.isValid, isTrue);
      expect(result.layoutIssues, isEmpty);
      expect(result.inventoryShortages, isEmpty);

      // 40 ft edges (e1, e3) require 2x20 ft each. 30 ft edges (e2, e4) require 20+10 ft each.
      // Total 20 ft = 2 + 2 + 1 + 1 = 6 pieces. Total 10 ft = 1 + 1 = 2 pieces.
      final p20 = catalog.getPieceByLength(Length.fromFeet(20.0))!;
      final p10 = catalog.getPieceByLength(Length.fromFeet(10.0))!;

      expect(result.requiredTrussBySize[p20], equals(6));
      expect(result.requiredTrussBySize[p10], equals(2));

      // Poles: 4 corners + 2 generated on 40 ft edges = 6 total poles
      expect(result.totalPoleCount, equals(6));
      expect(result.cornerPoleCount, equals(4));
      expect(result.generatedPoleCount, equals(2));
    });

    test('Detects zero-length edge in layout validation', () {
      final n1 = const NodeId('n1');
      final e1 = const EdgeId('e1');

      final layout = MandapLayout(
        nodes: {n1: MandapNode(id: n1, x: 10.0, z: 10.0)},
        edges: {
          e1: MandapEdge(
            id: e1,
            startNodeId: n1,
            endNodeId: n1,
          ), // Edge connected to same node
        },
      );

      final issues = layout.validate();
      expect(
        issues.any((i) => i.contains('connects node NodeId(n1) to itself')),
        isTrue,
      );
    });

    test('Detects missing node reference in layout validation', () {
      final n1 = const NodeId('n1');
      final n2 = const NodeId('n2_missing');
      final e1 = const EdgeId('e1');

      final layout = MandapLayout(
        nodes: {n1: MandapNode(id: n1, x: 0.0, z: 0.0)},
        edges: {e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2)},
      );

      final issues = layout.validate();
      expect(issues.any((i) => i.contains('missing end node')), isTrue);
    });
  });
}
