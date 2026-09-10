import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';

void main() {
  group('Standard Truss Size & Piece Requirement Calculations', () {
    test('Default standard truss piece size is 30 ft', () {
      final controller = MandapEditorController();
      expect(controller.standardTrussPieceSize, equals(30.0));
    });

    test('User sets 30 ft truss and total truss is 90 ft -> exactly 3 trusses required', () {
      final controller = MandapEditorController();
      controller.setStandardTrussPieceSize(30.0);

      // Create a layout with 3 edges of 30 ft each = 90 ft total
      const n1 = MandapNode(id: NodeId('n1'), x: 0, z: 0);
      const n2 = MandapNode(id: NodeId('n2'), x: 30, z: 0);
      const n3 = MandapNode(id: NodeId('n3'), x: 60, z: 0);
      const n4 = MandapNode(id: NodeId('n4'), x: 90, z: 0);

      final e1 = MandapEdge(id: const EdgeId('e1'), startNodeId: n1.id, endNodeId: n2.id);
      final e2 = MandapEdge(id: const EdgeId('e2'), startNodeId: n2.id, endNodeId: n3.id);
      final e3 = MandapEdge(id: const EdgeId('e3'), startNodeId: n3.id, endNodeId: n4.id);

      final customLayout = MandapLayout(
        nodes: {n1.id: n1, n2.id: n2, n3.id: n3, n4.id: n4},
        edges: {e1.id: e1, e2.id: e2, e3.id: e3},
        zones: const [],
      );

      controller.loadCustomLayout(customLayout);

      expect(controller.totalLinearTrussFt, equals(90.0));
      expect(controller.standardTrussPieceSize, equals(30.0));
      // 90 ft / 30 ft = 3 trusses required
      expect(controller.totalPiecesRequired, equals(3));
    });

    test('Calculation ceiling handles non-exact divisions correctly', () {
      final controller = MandapEditorController();
      controller.setStandardTrussPieceSize(30.0);

      // Layout with 100 ft total linear truss
      const n1 = MandapNode(id: NodeId('n1'), x: 0, z: 0);
      const n2 = MandapNode(id: NodeId('n2'), x: 100, z: 0);
      final e1 = MandapEdge(id: const EdgeId('e1'), startNodeId: n1.id, endNodeId: n2.id);

      final customLayout = MandapLayout(
        nodes: {n1.id: n1, n2.id: n2},
        edges: {e1.id: e1},
        zones: const [],
      );

      controller.loadCustomLayout(customLayout);

      expect(controller.totalLinearTrussFt, equals(100.0));
      // 100 / 30 = 3.33 -> 4 trusses required to span 100 ft
      expect(controller.totalPiecesRequired, equals(4));

      // Switch piece size to 25 ft
      controller.setStandardTrussPieceSize(25.0);
      // 100 / 25 = 4 trusses required
      expect(controller.totalPiecesRequired, equals(4));

      // Switch piece size to 20 ft
      controller.setStandardTrussPieceSize(20.0);
      // 100 / 20 = 5 trusses required
      expect(controller.totalPiecesRequired, equals(5));
    });
  });
}
