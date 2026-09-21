import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';

void main() {
  group('Center Point Multi-Directional Movement Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
    });

    test('Moving center point left/right and up/down updates center node and boundary midpoints', () {
      // 1. Toggle center cross to instantiate the center structure
      controller.toggleCenterCross();
      final centerNode = controller.centerControlNode;
      expect(centerNode, isNotNull);
      expect(centerNode!.x, equals(50.0));
      expect(centerNode.z, equals(50.0));

      // 2. Move center point in all directions: to (X: 35.0, Z: 65.0)
      controller.adjustCenterPosition(newX: 35.0, newZ: 65.0);

      final updatedCenter = controller.centerControlNode!;
      expect(updatedCenter.x, equals(35.0));
      expect(updatedCenter.z, equals(65.0));

      // 3. Verify North & South boundary nodes track X=35.0
      MandapNode? northMid;
      MandapNode? southMid;
      MandapNode? westMid;
      MandapNode? eastMid;

      for (final n in controller.layout.nodes.values) {
        if (n.id.value.contains('north') || (n.z - 0.0).abs() < 0.1 && (n.x - 35.0).abs() < 0.1) {
          northMid = n;
        }
        if (n.id.value.contains('south') || (n.z - 100.0).abs() < 0.1 && (n.x - 35.0).abs() < 0.1) {
          southMid = n;
        }
        if (n.id.value.contains('west') || (n.x - 0.0).abs() < 0.1 && (n.z - 65.0).abs() < 0.1) {
          westMid = n;
        }
        if (n.id.value.contains('east') || (n.x - 100.0).abs() < 0.1 && (n.z - 65.0).abs() < 0.1) {
          eastMid = n;
        }
      }

      expect(northMid, isNotNull);
      expect(northMid!.x, equals(35.0));
      expect(northMid.z, equals(0.0));

      expect(southMid, isNotNull);
      expect(southMid!.x, equals(35.0));
      expect(southMid.z, equals(100.0));

      expect(westMid, isNotNull);
      expect(westMid!.x, equals(0.0));
      expect(westMid.z, equals(65.0));

      expect(eastMid, isNotNull);
      expect(eastMid!.x, equals(100.0));
      expect(eastMid.z, equals(65.0));

      // 4. Test Undo
      controller.undo();
      final revertedCenter = controller.centerControlNode!;
      expect(revertedCenter.x, equals(50.0));
      expect(revertedCenter.z, equals(50.0));

      // 5. Test Redo
      controller.redo();
      final redoneCenter = controller.centerControlNode!;
      expect(redoneCenter.x, equals(35.0));
      expect(redoneCenter.z, equals(65.0));
    });

    test('Moving center point multiple times in various directions preserves structural integrity', () {
      controller.toggleCenterCross();

      // Move left & up
      controller.adjustCenterPosition(newX: 20.0, newZ: 25.0);
      expect(controller.centerControlNode!.x, equals(20.0));
      expect(controller.centerControlNode!.z, equals(25.0));

      // Move right & down
      controller.adjustCenterPosition(newX: 80.0, newZ: 75.0);
      expect(controller.centerControlNode!.x, equals(80.0));
      expect(controller.centerControlNode!.z, equals(75.0));

      // Check calculation result still produces valid poles and members
      expect(controller.result, isNotNull);
      expect(controller.result!.poles.length, greaterThanOrEqualTo(4));
    });
  });
}
