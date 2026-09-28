import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('Dynamic Plot Dimensions Tests', () {
    late MandapEditorController controller;

    setUp(() {
      controller = MandapEditorController(
        engine: const MandapCalculationEngine(),
      );
    });

    test('Initial 100x100 base architecture sets plotWidth and plotDepth to 100', () {
      controller.reconfigureTrussDimensions(
        plotLength: 100.0,
        plotWidth: 100.0,
        trussSize: 30.0,
      );

      expect(controller.plotWidth.round(), equals(100));
      expect(controller.plotDepth.round(), equals(100));
    });

    test('Increasing truss edge increases plotWidth, and decreasing it back returns to 100', () {
      controller.reconfigureTrussDimensions(
        plotLength: 100.0,
        plotWidth: 100.0,
        trussSize: 30.0,
      );

      // Find the last edge on the north wall connecting to the corner (90.0 -> 100.0)
      final edge = controller.layout.edges[EdgeId('e_north_3')]!;
      controller.selectEdge(edge.id);
      final originalLen = controller.selectedEdgeLength!;
      expect(originalLen, equals(10.0));

      // Increase from 10 to 20 ft (total width becomes 90 + 20 = 110 ft)
      final successIncrease = controller.resizeSelectedEdgeLength(20.0);
      expect(successIncrease, isTrue);
      expect(controller.plotWidth.round(), equals(110));

      // Decrease from 20 ft back down to 10 ft (total width becomes 90 + 10 = 100 ft)
      final successDecrease = controller.resizeSelectedEdgeLength(10.0);
      expect(successDecrease, isTrue);
      expect(controller.plotWidth.round(), equals(100));
    });

    test('Undo and redo accurately update plot dimensions', () {
      controller.reconfigureTrussDimensions(
        plotLength: 100.0,
        plotWidth: 100.0,
        trussSize: 30.0,
      );

      final edge = controller.layout.edges[EdgeId('e_north_3')]!;
      controller.selectEdge(edge.id);

      // Increase from 10 to 20 ft (total becomes 110 ft)
      controller.resizeSelectedEdgeLength(20.0);
      expect(controller.plotWidth.round(), equals(110));

      // Undo -> reverts to 100
      controller.undo();
      expect(controller.plotWidth.round(), equals(100));

      // Redo -> returns to 110
      controller.redo();
      expect(controller.plotWidth.round(), equals(110));
    });
  });
}
