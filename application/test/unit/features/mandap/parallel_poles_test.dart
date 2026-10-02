import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';

void main() {
  group('Parallel Poles Verification', () {
    test('Drawing parallel vertical truss line creates support poles at all intersections', () {
      final controller = MandapEditorController();
      controller.reconfigureTrussDimensions(
        plotWidth: 100.0,
        plotLength: 100.0,
        trussSize: 30.0,
      );

      // Verify base layout has perimeter poles
      expect(controller.layout.nodes.values.any((n) => n.x == 0.0 && n.z == 0.0), isTrue);

      // Add a horizontal inner truss line across Z = 30 ft (from 0 to 100)
      final nStartH = controller.getOrCreateNodeAt(0.0, 30.0, support: NodeSupport.pole);
      final nEndH = controller.getOrCreateNodeAt(100.0, 30.0, support: NodeSupport.pole);
      controller.addOrSubdivideEdge(nStartH, nEndH);

      // Now add a parallel vertical truss line at X = 10 ft (from Z = 0 to Z = 30 ft)
      final nStartV = controller.getOrCreateNodeAt(10.0, 0.0, support: NodeSupport.pole);
      final nEndV = controller.getOrCreateNodeAt(10.0, 30.0, support: NodeSupport.pole);
      controller.addOrSubdivideEdge(nStartV, nEndV);

      // Verify node at (10, 30) exists and has support pole
      final node10_30 = controller.layout.nodes.values.firstWhere(
        (n) => (n.x - 10.0).abs() < 0.5 && (n.z - 30.0).abs() < 0.5,
      );
      expect(node10_30, isNotNull);
      expect(node10_30.support, equals(NodeSupport.pole));

      // Verify calculation result contains pole at (10, 30)
      final poles = controller.result.poles;
      final poleAt10_30 = poles.where((p) => (p.x - 10.0).abs() < 0.5 && (p.z - 30.0).abs() < 0.5);
      expect(poleAt10_30.length, equals(1));
    });
  });
}
