import '../entities/truss_inventory.dart';
import '../entities/truss_piece_type.dart';
import '../value_objects/edge_solution.dart';
import '../value_objects/inventory_shortage.dart';

/// Aggregates Bill of Materials (BOM) and validates stock availability.
class InventoryValidator {
  /// Aggregates total required pieces per [TrussPieceType] across all edge solutions.
  static Map<TrussPieceType, int> aggregateBOM(List<EdgeSolution> solutions) {
    final bom = <TrussPieceType, int>{};

    for (final sol in solutions) {
      for (final piece in sol.pieces) {
        bom[piece] = (bom[piece] ?? 0) + 1;
      }
    }

    return Map.unmodifiable(bom);
  }

  /// Compares required BOM against available stock inventory.
  ///
  /// Returns a list of [InventoryShortage] items for any piece type with insufficient stock.
  static List<InventoryShortage> validateStock({
    required Map<TrussPieceType, int> requiredBOM,
    required TrussInventory inventory,
  }) {
    final shortages = <InventoryShortage>[];

    for (final entry in requiredBOM.entries) {
      final piece = entry.key;
      final requiredCount = entry.value;
      final availableCount = inventory.getAvailable(piece);

      if (requiredCount > availableCount) {
        shortages.add(
          InventoryShortage(
            pieceType: piece,
            requiredCount: requiredCount,
            availableCount: availableCount,
          ),
        );
      }
    }

    return List.unmodifiable(shortages);
  }
}
