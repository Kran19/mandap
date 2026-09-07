import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';
import 'package:mandap/spikes/renderer_3d/resize_edge_command.dart';
import 'package:mandap/spikes/renderer_3d/vector3d_math.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Phase 2 — 3D Technical Spike Engine Integration Tests', () {
    const engine = MandapCalculationEngine();
    final catalog = TrussCatalog.sample1To20Ft();
    final inventory = TrussInventory.sample(catalog, defaultQty: 50);

    test('3D Ray horizontal plane intersection math works accurately', () {
      final ray = Ray.originDirection(
        Vector3(0.0, 50.0, 0.0),
        Vector3(0.0, -1.0, 0.0),
      );

      final intersection = Vector3DMath.rayHorizontalPlaneIntersection(
        ray,
        10.0,
      );
      expect(intersection, isNotNull);
      expect(intersection!.y, equals(10.0));
      expect(intersection.x, equals(0.0));
      expect(intersection.z, equals(0.0));
    });

    test('3D Ray distance to line segment calculation works accurately', () {
      final p1 = Vector3(0.0, 10.0, 0.0);
      final p2 = Vector3(40.0, 10.0, 0.0);
      final point = Vector3(20.0, 10.0, 2.0);

      final dist = Vector3DMath.distanceToSegment(point, p1, p2);
      expect(dist, closeTo(2.0, 1e-5));
    });

    test('ResizeEdgeCommand executes and undoes cleanly on domain layout', () {
      var layout = MandapLayout.rectangle(
        width: Length.fromFeet(40.0),
        length: Length.fromFeet(30.0),
      );

      final e1 = const EdgeId('e1');
      final n2 = const NodeId('n2');

      // Command to resize edge e1 from 40 ft to 30.5 ft
      final cmd = ResizeEdgeCommand(
        edgeId: e1,
        movingNodeId: n2,
        oldX: 40.0,
        oldZ: 0.0,
        newX: 30.5,
        newZ: 0.0,
      );

      // Execute command
      layout = cmd.execute(layout);
      var result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );

      expect(layout.getEdgeLength(layout.getEdge(e1)!).feet, equals(30.5));
      // 30.5 ft edge e1 triggers 1 generated pole + 1 generated pole from 40ft edge e3 = 2 generated poles
      expect(result.generatedPoleCount, equals(2));

      // Undo command
      layout = cmd.undo(layout);
      result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );

      expect(layout.getEdgeLength(layout.getEdge(e1)!).feet, equals(40.0));
      expect(
        result.generatedPoleCount,
        equals(2),
      ); // Restored back to original 40ft rectangle poles
    });
  });
}
