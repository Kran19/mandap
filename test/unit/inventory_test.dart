import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/inventory_validator.dart';
import 'package:mandap/features/mandap/domain/services/truss_optimizer.dart';

void main() {
  group('Inventory & Shortage Validation Tests', () {
    final catalog = TrussCatalog.sample1To20Ft();

    test('Validates sufficient stock', () {
      final inventory = TrussInventory.sample(catalog, defaultQty: 100);

      final sol1 = TrussOptimizer.solveEdge(
        edgeId: const EdgeId('e1'),
        targetLength: Length.fromFeet(40.0), // 20 + 20
        catalog: catalog,
      );

      final bom = InventoryValidator.aggregateBOM([sol1]);
      final shortages = InventoryValidator.validateStock(
        requiredBOM: bom,
        inventory: inventory,
      );

      expect(shortages, isEmpty);
    });

    test('Detects single shortage', () {
      final p20 = catalog.getPieceByLength(Length.fromFeet(20.0))!;
      final inventory = TrussInventory({
        p20: 1,
      }); // Only 1 piece of 20 ft available

      final sol1 = TrussOptimizer.solveEdge(
        edgeId: const EdgeId('e1'),
        targetLength: Length.fromFeet(40.0), // Requires 2 x 20 ft
        catalog: catalog,
      );

      final bom = InventoryValidator.aggregateBOM([sol1]);
      final shortages = InventoryValidator.validateStock(
        requiredBOM: bom,
        inventory: inventory,
      );

      expect(shortages.length, equals(1));
      expect(shortages[0].pieceType, equals(p20));
      expect(shortages[0].requiredCount, equals(2));
      expect(shortages[0].availableCount, equals(1));
      expect(shortages[0].shortageCount, equals(1));
    });

    test(
      'CRITICAL TEST: Sufficient total linear footage but wrong piece sizes produces shortage',
      () {
        final p20 = catalog.getPieceByLength(Length.fromFeet(20.0))!;
        final p1 = catalog.getPieceByLength(Length.fromFeet(1.0))!;

        // User has 100 1-ft pieces (100 ft total linear footage), but 0 20-ft pieces
        final inventory = TrussInventory({p1: 100, p20: 0});

        final sol = TrussOptimizer.solveEdge(
          edgeId: const EdgeId('e1'),
          targetLength: Length.fromFeet(40.0), // Requires 2 x 20 ft
          catalog: catalog,
        );

        final bom = InventoryValidator.aggregateBOM([sol]);
        final shortages = InventoryValidator.validateStock(
          requiredBOM: bom,
          inventory: inventory,
        );

        expect(shortages.length, equals(1));
        expect(shortages[0].pieceType, equals(p20));
        expect(shortages[0].shortageCount, equals(2));
      },
    );
  });
}
