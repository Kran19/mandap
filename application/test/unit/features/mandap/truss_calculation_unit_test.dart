import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';

void main() {
  group('Truss Calculation Unit Size Tests', () {
    test('Defaults to 10ft unit calculation size', () {
      final controller = MandapEditorController();
      expect(controller.trussCalculationUnitSize, 10.0);
    });

    test('Recalculates piece requirements dynamically when unit size is updated', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
      );

      final totalFt = controller.totalLinearTrussFt;
      expect(totalFt, greaterThan(0));

      // 1. Default 10ft calculation
      controller.setTrussCalculationUnitSize(10.0);
      final piecesAt10 = controller.totalPiecesRequired;
      expect(piecesAt10, equals((totalFt / 10.0).ceil()));

      // 2. Custom 15ft calculation
      controller.setTrussCalculationUnitSize(15.0);
      expect(controller.trussCalculationUnitSize, 15.0);
      final piecesAt15 = controller.totalPiecesRequired;
      expect(piecesAt15, equals((totalFt / 15.0).ceil()));

      // 3. Custom 20ft calculation
      controller.setTrussCalculationUnitSize(20.0);
      expect(controller.trussCalculationUnitSize, 20.0);
      final piecesAt20 = controller.totalPiecesRequired;
      expect(piecesAt20, equals((totalFt / 20.0).ceil()));

      // 4. Custom arbitrary value (e.g. 12.5 ft)
      controller.setTrussCalculationUnitSize(12.5);
      expect(controller.trussCalculationUnitSize, 12.5);
      final piecesAt12_5 = controller.totalPiecesRequired;
      expect(piecesAt12_5, equals((totalFt / 12.5).ceil()));

      // Pillar vs Upper piece breakdown
      expect(
        controller.pillarPiecesRequired,
        equals((controller.pillarTotalFeet / 12.5).ceil()),
      );
      expect(
        controller.upperPiecesRequired,
        equals((controller.upperTotalFeet / 12.5).ceil()),
      );
    });
  });
}
