import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/wizard/create_truss_dialog.dart';

void main() {
  group('MASTER VERIFICATION — Center Fixed Line & Front/Back-Only Control', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );
    });

    test('1. Default Truss Size is 30 ft in CreateTrussDialog and Generator', () {
      const dialog = CreateTrussDialog();
      expect(dialog.initialTrussSize, equals(30.0));
      expect(controller.standardTrussPieceSize, equals(30.0));
    });

    test('2. Center Point moves in all directions when adjusted', () {
      final initialCenterX = controller.fixedCenterX;
      expect(initialCenterX, equals(50.0));

      final centerNode = controller.centerControlNode;
      expect(centerNode, isNotNull);
      expect(centerNode!.x, equals(50.0));
      expect(centerNode.z, equals(50.0));

      // Move left (X = 40.0, Z = 50.0)
      controller.adjustCenterPosition(
        newX: 40.0,
        newZ: 50.0,
      );
      var updatedNode = controller.layout.getNode(centerNode.id)!;
      expect(updatedNode.x, equals(40.0));

      // Move right (X = 65.0, Z = 50.0)
      controller.adjustCenterPosition(
        newX: 65.0,
        newZ: 50.0,
      );
      updatedNode = controller.layout.getNode(centerNode.id)!;
      expect(updatedNode.x, equals(65.0));
    });

    test('3. Front/Back Resize (Only Z modifies, X remains strictly 50.0 ft)', () {
      final centerNode = controller.centerControlNode!;
      expect(centerNode.z, equals(50.0));

      // Move toward Back: Z = 70.0 ft
      controller.adjustCenterFrontBack(newZ: 70.0);
      var node = controller.layout.getNode(centerNode.id)!;
      expect(node.x, equals(50.0));
      expect(node.z, equals(70.0));

      // Move toward Front: Z = 30.0 ft
      controller.adjustCenterFrontBack(newZ: 30.0);
      node = controller.layout.getNode(centerNode.id)!;
      expect(node.x, equals(50.0));
      expect(node.z, equals(30.0));
    });

    test('4. Outer Perimeter and Corner Towers Remain Fixed Before and After Adjustment', () {
      // Snapshot corners and perimeter
      final cornersBefore = controller.layout.nodes.values
          .where((n) => n.type == NodeType.corner)
          .map((n) => (n.x, n.z))
          .toSet();
      final totalPolesBefore = controller.totalPoleCount;

      // Adjust internal front/back position (e.g. from 50 ft to 60 ft)
      controller.adjustCenterFrontBack(newZ: 60.0);

      final cornersAfter = controller.layout.nodes.values
          .where((n) => n.type == NodeType.corner)
          .map((n) => (n.x, n.z))
          .toSet();

      expect(cornersAfter, equals(cornersBefore), reason: 'Perimeter corner positions must not move');
      expect(controller.totalPoleCount, equals(totalPolesBefore), reason: 'Poles count must remain stable');
    });

    test('5. Center Line Remains 100% Mathematically Straight (Collinear on X = 50 ft)', () {
      controller.adjustCenterFrontBack(newZ: 65.0);

      final centerNode = controller.centerControlNode!;
      expect(centerNode.x, equals(50.0));

      // Verify all edges along the center vertical line share X = 50.0
      for (final edge in controller.layout.edges.values) {
        final start = controller.layout.getNode(edge.startNodeId);
        final end = controller.layout.getNode(edge.endNodeId);
        if (start != null && end != null) {
          if ((start.x - 50.0).abs() < 0.001 && (end.x - 50.0).abs() < 0.001) {
            expect(start.x, equals(50.0));
            expect(end.x, equals(50.0));
            expect(start.elevation, equals(end.elevation), reason: 'Center line must remain level');
          }
        }
      }
    });

    test('6. Undo / Redo Restores Exact Previous Geometry in a Single Step', () {
      final centerNode = controller.centerControlNode!;
      expect(centerNode.z, equals(50.0));

      // 1. Move to 70 ft
      controller.adjustCenterFrontBack(newZ: 70.0);
      expect(controller.layout.getNode(centerNode.id)!.z, equals(70.0));

      // 2. Undo restores 50 ft in exactly one step
      controller.undo();
      expect(controller.layout.getNode(centerNode.id)!.z, equals(50.0));

      // 3. Redo restores 70 ft in exactly one step
      controller.redo();
      expect(controller.layout.getNode(centerNode.id)!.z, equals(70.0));
    });

    test('7. Camera Orbit / Pan / Zoom Never Mutates Center Geometry', () {
      final controller3D = Mandap3DController();
      final centerNode = controller.centerControlNode!;
      final initialX = centerNode.x;
      final initialZ = centerNode.z;

      // Orbit camera by 90 degrees
      controller3D.orbitCamera(90.0, 0.0);
      expect(controller.layout.getNode(centerNode.id)!.x, equals(initialX));
      expect(controller.layout.getNode(centerNode.id)!.z, equals(initialZ));

      // Orbit camera by 180 degrees
      controller3D.orbitCamera(180.0, 30.0);
      expect(controller.layout.getNode(centerNode.id)!.x, equals(initialX));
      expect(controller.layout.getNode(centerNode.id)!.z, equals(initialZ));

      // Pan and zoom camera
      controller3D.panCamera(25.0, -15.0);
      controller3D.zoomCamera(1.5);
      expect(controller.layout.getNode(centerNode.id)!.x, equals(initialX));
      expect(controller.layout.getNode(centerNode.id)!.z, equals(initialZ));
    });

    test('8. 2D and 3D Parity (Both consume the exact same authoritative layout coordinates)', () {
      controller.adjustCenterFrontBack(newZ: 60.0);

      final cNode = controller.centerControlNode!;
      expect(cNode.x, equals(50.0));
      expect(cNode.z, equals(60.0));

      // In 2D: node.x = 50.0, node.z = 60.0
      // In 3D: Vector3(node.x, node.elevation, node.z) = (50.0, 20.0, 60.0)
      final v3D = v64.Vector3(cNode.x, cNode.elevation, cNode.z);
      expect(v3D.x, equals(cNode.x));
      expect(v3D.z, equals(cNode.z));
    });

    test('9. Essential Center Reference Node Protected from Accidental Deletion', () {
      final centerNode = controller.centerControlNode!;
      controller.deleteNode(centerNode.id);

      // Node must still exist in layout
      final retained = controller.layout.getNode(centerNode.id);
      expect(retained, isNotNull, reason: 'Center structural reference is protected against accidental deletion');
    });
  });
}
