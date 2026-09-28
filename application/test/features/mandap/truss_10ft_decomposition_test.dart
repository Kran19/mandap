import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('10ft Modular Truss Calculation Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        engine: const MandapCalculationEngine(),
      );
    });

    test('30ft truss edge decomposes into exactly 3 pieces of 10ft truss', () {
      controller.clearAll();
      final n1 = controller.addNodeNamed(x: 0, z: 0, type: NodeType.corner, support: NodeSupport.pole);
      final n2 = controller.addNodeNamed(x: 30, z: 0, type: NodeType.corner, support: NodeSupport.pole);
      controller.createTrussMember(startNodeId: n1!, endNodeId: n2!);

      final requiredTruss = controller.result.requiredTrussBySize;
      expect(requiredTruss.isNotEmpty, isTrue);

      // Find 10ft piece
      final piece10 = requiredTruss.entries.firstWhere((e) => e.key.length.feet == 10.0);
      expect(piece10.value, equals(3)); // 30ft = 3x 10ft
    });

    test('25ft truss edge decomposes into 2x 10ft + 1x 5ft pieces', () {
      controller.clearAll();
      final n1 = controller.addNodeNamed(x: 0, z: 0, type: NodeType.corner, support: NodeSupport.pole);
      final n2 = controller.addNodeNamed(x: 25, z: 0, type: NodeType.corner, support: NodeSupport.pole);
      controller.createTrussMember(startNodeId: n1!, endNodeId: n2!);

      final requiredTruss = controller.result.requiredTrussBySize;
      final piece10 = requiredTruss.entries.firstWhere((e) => e.key.length.feet == 10.0);
      final piece5 = requiredTruss.entries.firstWhere((e) => e.key.length.feet == 5.0);

      expect(piece10.value, equals(2)); // 2x 10ft = 20ft
      expect(piece5.value, equals(1));  // 1x 5ft = 5ft
    });

    test('Standard 100x100 layout with 30ft box spacing decomposes all spans into 10ft modular pieces', () {
      controller.reconfigureTrussDimensions(
        plotLength: 100.0,
        plotWidth: 100.0,
        trussSize: 30.0,
      );

      final requiredTruss = controller.result.requiredTrussBySize;
      // All piece sizes in requiredTruss must be <= 10.0 ft
      for (final piece in requiredTruss.keys) {
        expect(piece.length.feet, lessThanOrEqualTo(10.0));
      }

      // 100ft perimeter has: 4 walls of 100ft each = 400ft total span
      // 400ft / 10ft = 40 pieces of 10ft truss
      final piece10 = requiredTruss.entries.firstWhere((e) => e.key.length.feet == 10.0);
      expect(piece10.value, equals(40));
    });
  });
}
