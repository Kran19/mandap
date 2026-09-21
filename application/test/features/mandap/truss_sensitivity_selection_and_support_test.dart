import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart';
import 'package:mandap/features/mandap/presentation/mandap_editor_screen.dart';
import 'package:mandap/features/mandap/presentation/top_view_2d/mandap_2d_interactive_painter.dart';

void main() {
  group('Truss Sensitivity, Selection Indicator & Support Verification Tests', () {
    test('1. Mandap3DController camera orbit sensitivity is smooth (0.0038)', () {
      final controller3D = Mandap3DController();
      final initialAzimuth = controller3D.cameraAzimuth;
      final initialElevation = controller3D.cameraElevation;

      // Simulate 100px swipe
      controller3D.orbitCamera(100.0, 50.0);

      expect(controller3D.cameraAzimuth, closeTo(initialAzimuth + 100.0 * 0.0038, 0.0001));
      expect(controller3D.cameraElevation, closeTo(initialElevation - 50.0 * 0.0038, 0.0001));
    });

    test('2. Support pole paints have unselected Red and selected Blue colors', () {
      expect(Truss3DPaints.supportPoleUnselected.color.value, const Color(0xFFEF4444).value); // Red
      expect(Truss3DPaints.supportPoleSelected.color.value, const Color(0xFF00E5FF).value); // Vibrant Blue/Cyan
    });

    test('3. checkCenterCrossSupport correctly validates Forward, Backward, Left, Right poles', () {
      // Create controller with default 100x100 layout (has corners at 0,0; 100,0; 100,100; 0,100)
      final controller = MandapEditorController(initialWidth: 100, initialDepth: 100);

      final check = controller.checkCenterCrossSupport();
      expect(check.canActivate, isTrue);
      expect(check.missingDirections, isEmpty);

      // Now test with missing forward (North) poles
      final southOnlyNodes = <NodeId, MandapNode>{
        const NodeId('s1'): const MandapNode(
          id: NodeId('s1'),
          x: 0,
          z: 100,
          elevation: 20,
          support: NodeSupport.pole,
          type: NodeType.corner,
        ),
        const NodeId('s2'): const MandapNode(
          id: NodeId('s2'),
          x: 100,
          z: 100,
          elevation: 20,
          support: NodeSupport.pole,
          type: NodeType.corner,
        ),
      };

      final customLayout = MandapLayout(nodes: southOnlyNodes, edges: const {}, zones: const []);
      controller.loadCustomLayout(customLayout);

      final customCheck = controller.checkCenterCrossSupport();
      expect(customCheck.canActivate, isFalse);
      expect(customCheck.missingDirections, equals(['Forward (North)']));
    });

    test('4. checkCenterCrossSupport detects specific missing directions correctly', () {
      final controller = MandapEditorController(initialWidth: 100, initialDepth: 100);

      // Layout with forward, backward, right poles, but NO left (West x <= 20) poles
      final nodesWithoutWest = <NodeId, MandapNode>{
        const NodeId('n1'): const MandapNode(
          id: NodeId('n1'),
          x: 50,
          z: 0,
          elevation: 20,
          support: NodeSupport.pole,
          type: NodeType.corner,
        ), // North
        const NodeId('n2'): const MandapNode(
          id: NodeId('n2'),
          x: 50,
          z: 100,
          elevation: 20,
          support: NodeSupport.pole,
          type: NodeType.corner,
        ), // South
        const NodeId('n3'): const MandapNode(
          id: NodeId('n3'),
          x: 100,
          z: 50,
          elevation: 20,
          support: NodeSupport.pole,
          type: NodeType.corner,
        ), // East / Right
      };

      controller.loadCustomLayout(MandapLayout(nodes: nodesWithoutWest, edges: const {}, zones: const []));
      final check = controller.checkCenterCrossSupport();
      expect(check.canActivate, isFalse);
      expect(check.missingDirections, contains('Left (West)'));
      expect(check.missingDirections, isNot(contains('Forward (North)')));
      expect(check.missingDirections, isNot(contains('Backward (South)')));
      expect(check.missingDirections, isNot(contains('Right (East)')));
    });

    test('5. Node selection in controller updates selectedNodeId for 2D & 3D highlight', () {
      final controller = MandapEditorController(initialWidth: 100, initialDepth: 100);
      final firstNodeId = controller.layout.nodes.keys.first;

      controller.selectNode(firstNodeId);
      expect(controller.selectedNodeId, equals(firstNodeId));

      controller.clearSelection();
      expect(controller.selectedNodeId, isNull);
    });
  });
}
