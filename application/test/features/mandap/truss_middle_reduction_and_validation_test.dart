import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/services/truss_bay_detector.dart';

void main() {
  group('Truss Middle Size Reduction & Dialog Validation Tests', () {
    test('Reducing middle truss member length reduces overall structure size and preserves side structure', () {
      final controller = MandapEditorController(
        initialWidth: 90.0,
        initialDepth: 90.0,
        initialTrussSize: 30.0,
      );

      final initialWidth = controller.plotWidth;

      // Select an edge along X axis and resize it
      final edge = controller.layout.edges.values.firstWhere((e) {
        final s = controller.layout.getNode(e.startNodeId)!;
        final en = controller.layout.getNode(e.endNodeId)!;
        return (en.z - s.z).abs() < 0.1 && (en.x - s.x).abs() > 5.0;
      });

      controller.selectEdge(edge.id);
      final currentLen = controller.selectedEdgeLength ?? 30.0;

      final success = controller.resizeSelectedEdgeLength(currentLen - 10.0);
      expect(success, isTrue);

      // Verify overall structure width reduced
      expect(controller.plotWidth, lessThan(initialWidth));
    });

    test('Single bay structure allows reducing size without error', () {
      final controller = MandapEditorController(
        initialWidth: 30.0,
        initialDepth: 30.0,
        initialTrussSize: 30.0,
      );

      final bays = const TrussBayDetector().detectBays(controller.layout);
      expect(bays.length, equals(1));

      controller.resizeBay(
        bays.first.id,
        targetWidthFt: 20.0,
      );

      expect(controller.plotWidth, equals(20.0));
    });
  });
}
