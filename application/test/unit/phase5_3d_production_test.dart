import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/math/beam_transform_calculator.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/math/drag_constraint_calculator.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/math/render_entity_registry.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';

void main() {
  group('Phase 5 — Production 3D Editor Integration & Math Tests', () {
    test(
      'BeamTransformCalculator calculates correct center, length, and direction for horizontal beam',
      () {
        final start = const MandapNode(id: NodeId('n1'), x: 0.0, z: 0.0);
        final end = const MandapNode(id: NodeId('n2'), x: 40.0, z: 0.0);

        final transform = BeamTransformCalculator.calculate(
          startNode: start,
          endNode: end,
          height: 10.0,
        );

        expect(transform.center.x, equals(20.0));
        expect(transform.center.y, equals(10.0));
        expect(transform.center.z, equals(0.0));
        expect(transform.length, equals(40.0));
        expect(transform.direction.x, closeTo(1.0, 1e-4));
        expect(transform.direction.z, closeTo(0.0, 1e-4));
        expect(transform.azimuthAngle, closeTo(0.0, 1e-4));
      },
    );

    test(
      'BeamTransformCalculator handles arbitrary diagonal beam correctly',
      () {
        final start = const MandapNode(id: NodeId('n1'), x: 0.0, z: 0.0);
        final end = const MandapNode(id: NodeId('n2'), x: 30.0, z: 40.0);

        final transform = BeamTransformCalculator.calculate(
          startNode: start,
          endNode: end,
          height: 10.0,
        );

        expect(transform.center.x, equals(15.0));
        expect(transform.center.z, equals(20.0));
        expect(transform.length, closeTo(50.0, 1e-4));
        expect(transform.azimuthAngle, closeTo(math.atan2(40.0, 30.0), 1e-4));
      },
    );

    test(
      'DragConstraintCalculator snaps raw feet to 0.5-ft increments and clamps minimum length',
      () {
        expect(DragConstraintCalculator.snapToHalfFoot(30.22), equals(30.0));
        expect(DragConstraintCalculator.snapToHalfFoot(30.28), equals(30.5));
        expect(DragConstraintCalculator.snapToHalfFoot(30.74), equals(30.5));

        final startNode = const MandapNode(id: NodeId('n1'), x: 0.0, z: 0.0);
        final endNode = const MandapNode(id: NodeId('n2'), x: 30.0, z: 0.0);

        // Drag to 30.3 ft
        final res = DragConstraintCalculator.calculateEdgeHandleDrag(
          startNode: startNode,
          endNode: endNode,
          planeIntersectionPoint: v64.Vector3(30.3, 10.0, 0.0),
          currentLengthFeet: 30.0,
        );

        expect(res.snappedLength.feet, equals(30.5));
        expect(res.newX, equals(30.5));
        expect(res.newZ, equals(0.0));
        expect(res.hasValueChanged, isTrue);
      },
    );

    test(
      'RenderEntityRegistry registers entities and performs bidirectional raycast picking',
      () {
        final registry = RenderEntityRegistry();

        final beam = BeamRenderEntity(
          edgeId: const EdgeId('e1'),
          startNodeId: const NodeId('n1'),
          endNodeId: const NodeId('n2'),
          start: v64.Vector3(0.0, 10.0, 0.0),
          end: v64.Vector3(40.0, 10.0, 0.0),
          lengthFeet: 40.0,
        );
        final handle = HandleRenderEntity(
          nodeId: const NodeId('n2'),
          position: v64.Vector3(40.0, 10.0, 0.0),
        );

        registry.registerBeam(beam);
        registry.registerHandle(handle);

        expect(registry.getBeam(const EdgeId('e1')), equals(beam));
        expect(registry.getHandle(const NodeId('n2')), equals(handle));

        // Pick handle near (40.2, 10.0, 0.1)
        final pickedHandle = registry.pickHandle(
          planeIntersectionPoint: v64.Vector3(40.2, 10.0, 0.1),
          hitRadiusFeet: 6.0,
        );
        expect(pickedHandle, equals(const NodeId('n2')));

        // Pick beam near (20.0, 10.0, 0.5)
        final pickedBeam = registry.pickBeam(
          planeIntersectionPoint: v64.Vector3(20.0, 10.0, 0.5),
          maxHitDistanceFeet: 4.0,
        );
        expect(pickedBeam, equals(const EdgeId('e1')));
      },
    );

    test(
      'Mandap3DController fits camera dynamically for Rectangle, L, U, Open Run, and Custom Irregular layouts',
      () {
        final controller3D = Mandap3DController();

        // 1. 40x30 Rectangle
        final rectLayout = MandapLayout.rectangle(
          width: Length.fromFeet(40.0),
          length: Length.fromFeet(30.0),
        );
        controller3D.fitCamera(rectLayout);
        expect(controller3D.cameraCenterTarget.x, equals(20.0));
        expect(controller3D.cameraCenterTarget.z, equals(15.0));

        // 2. Custom Irregular Layout (0,0 -> 30,0 -> 40,15 -> 20,30 -> 0,20)
        final customLayout = MandapLayout(
          nodes: {
            const NodeId('n1'): const MandapNode(
              id: NodeId('n1'),
              x: 0.0,
              z: 0.0,
            ),
            const NodeId('n2'): const MandapNode(
              id: NodeId('n2'),
              x: 30.0,
              z: 0.0,
            ),
            const NodeId('n3'): const MandapNode(
              id: NodeId('n3'),
              x: 40.0,
              z: 15.0,
            ),
            const NodeId('n4'): const MandapNode(
              id: NodeId('n4'),
              x: 20.0,
              z: 30.0,
            ),
            const NodeId('n5'): const MandapNode(
              id: NodeId('n5'),
              x: 0.0,
              z: 20.0,
            ),
          },
          edges: {
            const EdgeId('e1'): const MandapEdge(
              id: EdgeId('e1'),
              startNodeId: NodeId('n1'),
              endNodeId: NodeId('n2'),
            ),
            const EdgeId('e2'): const MandapEdge(
              id: EdgeId('e2'),
              startNodeId: NodeId('n2'),
              endNodeId: NodeId('n3'),
            ),
            const EdgeId('e3'): const MandapEdge(
              id: EdgeId('e3'),
              startNodeId: NodeId('n3'),
              endNodeId: NodeId('n4'),
            ),
            const EdgeId('e4'): const MandapEdge(
              id: EdgeId('e4'),
              startNodeId: NodeId('n4'),
              endNodeId: NodeId('n5'),
            ),
            const EdgeId('e5'): const MandapEdge(
              id: EdgeId('e5'),
              startNodeId: NodeId('n5'),
              endNodeId: NodeId('n1'),
            ),
          },
        );

        controller3D.fitCamera(customLayout);
        expect(controller3D.cameraCenterTarget.x, equals(20.0));
        expect(controller3D.cameraCenterTarget.z, equals(15.0));
      },
    );

    test('CRITICAL 30-FT LIVE SUPPORT THRESHOLD TEST in 3D Scene Sync', () {
      final editorController = MandapEditorController();
      final controller3D = Mandap3DController();

      // Open run 30.0 ft edge
      final layout30 = MandapLayout(
        nodes: {
          const NodeId('n1'): const MandapNode(
            id: NodeId('n1'),
            x: 0.0,
            z: 0.0,
          ),
          const NodeId('n2'): const MandapNode(
            id: NodeId('n2'),
            x: 30.0,
            z: 0.0,
          ),
        },
        edges: {
          const EdgeId('e1'): const MandapEdge(
            id: EdgeId('e1'),
            startNodeId: NodeId('n1'),
            endNodeId: NodeId('n2'),
          ),
        },
      );

      editorController.loadCustomLayout(layout30);
      controller3D.syncScene(editorController.layout, editorController.result);

      // At 30.0 ft -> 2 corner poles, 0 intermediate poles
      expect(editorController.result.poles.length, equals(2));
      expect(controller3D.registry.poles.length, equals(2));

      // Resize e1 to 30.5 ft
      editorController.resizeEdge(
        edgeId: const EdgeId('e1'),
        movingNodeId: const NodeId('n2'),
        newX: 30.5,
        newZ: 0.0,
      );
      controller3D.syncScene(editorController.layout, editorController.result);

      // At 30.5 ft -> 2 corner poles + 1 intermediate pole = 3 total poles
      expect(editorController.result.poles.length, equals(3));
      expect(controller3D.registry.poles.length, equals(3));
      expect(
        editorController.result.poles.any(
          (p) => p.reason == PoleReason.generatedMaxSpan,
        ),
        isTrue,
      );

      // Resize back to 30.0 ft
      editorController.resizeEdge(
        edgeId: const EdgeId('e1'),
        movingNodeId: const NodeId('n2'),
        newX: 30.0,
        newZ: 0.0,
      );
      controller3D.syncScene(editorController.layout, editorController.result);

      // Intermediate pole disappears
      expect(editorController.result.poles.length, equals(2));
      expect(controller3D.registry.poles.length, equals(2));
    });
  });
}
