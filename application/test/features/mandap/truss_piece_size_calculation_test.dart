import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';

void main() {
  group('Truss Piece Size Calculation Tests', () {
    test('When user specifies 10 ft truss size, BOM decomposes into 10 ft trusses and no 30 ft trusses', () {
      final controller = MandapEditorController(
        initialWidth: 50.0,
        initialDepth: 50.0,
        initialTrussSize: 10.0,
      );

      // Verify catalog only contains piece sizes <= 10.0
      expect(controller.catalog.pieceTypes.every((p) => p.length.feet <= 10.0), isTrue);

      final result = controller.result;
      expect(result, isNotNull);

      // Check requiredTrussBySize:
      // No piece should be > 10.0 ft
      for (final piece in result.requiredTrussBySize.keys) {
        expect(piece.length.feet, lessThanOrEqualTo(10.0),
            reason: 'Truss piece ${piece.length.feet}ft should not exceed user standard 10ft');
      }

      // Check that 10 ft pieces are used
      final piece10 = result.requiredTrussBySize.entries.firstWhere(
        (e) => (e.key.length.feet - 10.0).abs() < 0.1,
      );
      expect(piece10.value, greaterThan(0));
    });

    test('Switching standard truss size dynamically recalculates BOM to new piece size', () {
      final controller = MandapEditorController(
        initialWidth: 60.0,
        initialDepth: 60.0,
        initialTrussSize: 30.0,
      );

      // Initially 30 ft
      expect(controller.catalog.pieceTypes.any((p) => (p.length.feet - 30.0).abs() < 0.1), isTrue);

      // Change to 10 ft
      controller.setStandardTrussPieceSize(10.0);
      expect(controller.standardTrussPieceSize, equals(10.0));
      expect(controller.catalog.pieceTypes.every((p) => p.length.feet <= 10.0), isTrue);

      for (final piece in controller.result.requiredTrussBySize.keys) {
        expect(piece.length.feet, lessThanOrEqualTo(10.0));
      }
    });
  });
}
