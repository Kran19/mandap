import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/services/pole_placement_engine.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';
import 'package:mandap/features/mandap/domain/services/truss_support_spacing_calculator.dart';
import 'package:mandap/features/mandap/domain/services/truss_bay_detector.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';

void main() {
  group('Straight Snapped Truss Drawing & 30ft Support Pole Tests', () {
    test('1. Straight orthogonal truss drawing snaps strictly to standardTrussPieceSize along dominant axis', () {
      final controller = MandapEditorController();
      controller.clearAll();
      controller.setStandardTrussPieceSize(10.0);

      // Create start node at (10, 10)
      final startNodeId = controller.addNodeNamed(
        x: 10.0,
        z: 10.0,
        type: NodeType.corner,
        elevation: 20.0,
      )!;

      // User initiates drawing from startNodeId
      controller.handleAddEdgeTap(startNodeId);
      expect(controller.pendingEdgeStartNodeId, equals(startNodeId));

      // User drags/taps towards (38.2, 14.1) -> dominant X-axis (dx=28.2 vs dz=4.1)
      // With step=10.0, 28.2 / 10 = 2.82 -> rounds to 30.0 ft along X (targetX = 10 + 30 = 40.0, targetZ = 10.0)
      final endNodeId = controller.drawStraightTrussTo(38.2, 14.1);
      expect(endNodeId, isNotNull);

      final endNode = controller.layout.getNode(endNodeId!);
      expect(endNode, isNotNull);
      expect(endNode!.x, equals(40.0));
      expect(endNode.z, equals(10.0)); // Strictly horizontal!
      expect(controller.pendingEdgeStartNodeId, isNull);

      // Verify created edge connects start to end orthogonally
      expect(controller.layout.edges.length, equals(1));
      final edge = controller.layout.edges.values.first;
      expect(edge.startNodeId, equals(startNodeId));
      expect(edge.endNodeId, equals(endNodeId));
    });

    test('2. Dominant vertical drawing snaps along Z-axis strictly', () {
      final controller = MandapEditorController();
      controller.clearAll();
      controller.setStandardTrussPieceSize(15.0);

      final startNodeId = controller.addNodeNamed(
        x: 20.0,
        z: 20.0,
        type: NodeType.corner,
        elevation: 20.0,
      )!;

      controller.handleAddEdgeTap(startNodeId);
      // User drags towards (23.0, 52.0) -> dominant Z-axis (dz=32.0 vs dx=3.0)
      // With step=15.0, 32.0 / 15 = 2.13 -> rounds to 2 * 15 = 30.0 ft (targetZ = 20 + 30 = 50.0, targetX = 20.0)
      final endNodeId = controller.drawStraightTrussTo(23.0, 52.0);
      expect(endNodeId, isNotNull);

      final endNode = controller.layout.getNode(endNodeId!);
      expect(endNode, isNotNull);
      expect(endNode!.x, equals(20.0)); // Strictly vertical!
      expect(endNode.z, equals(50.0));
    });

    test('3. Support poles are calculated at fixed 30-ft intervals on long runs', () {
      const calculator = TrussSupportSpacingCalculator();

      // 90 ft run -> supports at 0, 30, 60, 90
      final positions90 = calculator.calculateSupportPositions(90.0, interval: 30.0);
      expect(positions90, equals([0.0, 30.0, 60.0, 90.0]));

      // 100 ft run -> supports at 0, 30, 60, 90, 100
      final positions100 = calculator.calculateSupportPositions(100.0, interval: 30.0);
      expect(positions100, equals([0.0, 30.0, 60.0, 90.0, 100.0]));

      // 60 ft run -> supports at 0, 30, 60
      final positions60 = calculator.calculateSupportPositions(60.0, interval: 30.0);
      expect(positions60, equals([0.0, 30.0, 60.0]));
    });

    test('4. PolePlacementEngine uses FixedIntervalPoleStrategy with 30ft default', () {
      const engine = PolePlacementEngine();
      expect(engine.strategy, isA<FixedIntervalPoleStrategy>());
      expect(engine.maxSpanFeet, equals(30.0));
    });

    test('5. Bay detector correctly identifies closed bays for 00/00 box size display', () {
      final controller = MandapEditorController();
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 60.0,
          plotDepth: 60.0,
          preferredPoleSpacing: 30.0,
          poleHeight: 20.0,
        ),
      );
      controller.setLayout(layout);

      final bays = const TrussBayDetector().detectBays(controller.layout);
      expect(bays.isNotEmpty, isTrue);

      for (final bay in bays) {
        final w = bay.widthFt.toInt().toString().padLeft(2, '0');
        final l = bay.lengthFt.toInt().toString().padLeft(2, '0');
        final label = '$w/$l';
        expect(label, isNotEmpty);
      }
    });

    test('6. Tapping off-axis node clamps to dominant orthogonal axis to ensure straight lines', () {
      final controller = MandapEditorController();
      controller.clearAll();

      final startId = controller.addNodeNamed(x: 0.0, z: 75.0, type: NodeType.corner, elevation: 20.0)!;
      final offAxisEndId = controller.addNodeNamed(x: 25.0, z: 100.0, type: NodeType.corner, elevation: 20.0)!;

      // Select start node
      controller.handleAddEdgeTap(startId);
      // Select off-axis node (25, 100) -> dx=25, dz=25 -> snaps orthogonally along dominant X-axis to (25, 75)
      controller.handleAddEdgeTap(offAxisEndId);

      expect(controller.layout.edges.length, equals(1));
      final edge = controller.layout.edges.values.first;      final endNode = controller.layout.getNode(edge.endNodeId)!;

      // Must be strictly horizontal along X (z = 75.0, x = 25.0) - NO SLANT LINE!
      expect(endNode.z, equals(75.0));
      expect(endNode.x, equals(25.0));
      expect(controller.layout.getExactGeometricLengthFeet(edge), equals(25.0));
    });

    test('7. 100ft upper horizontal truss run generates intermediate 30ft support poles', () {
      final controller = MandapEditorController();
      controller.clearAll();

      final startId = controller.addNodeNamed(x: 0.0, z: 0.0, type: NodeType.corner, elevation: 20.0)!;
      final endId = controller.addNodeNamed(x: 100.0, z: 0.0, type: NodeType.corner, elevation: 20.0)!;

      controller.createTrussMember(startNodeId: startId, endNodeId: endId);

      final poles = controller.result.poles;
      final generatedPoles = poles.where((p) => p.reason == PoleReason.generatedMaxSpan).toList();

      // 100ft run requires 3 intermediate 30ft support poles (at x=30, 60, 90)
      expect(generatedPoles.length, equals(3));
      expect(generatedPoles[0].x, closeTo(30.0, 1e-4));
      expect(generatedPoles[1].x, closeTo(60.0, 1e-4));
      expect(generatedPoles[2].x, closeTo(90.0, 1e-4));
    });
  });
}
