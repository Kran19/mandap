import '../entities/edge_id.dart';
import '../entities/mandap_layout.dart';
import '../entities/truss_catalog.dart';
import '../entities/truss_inventory.dart';
import '../value_objects/edge_solution.dart';
import '../value_objects/mandap_calculation_result.dart';
import '../entities/mandap_zone.dart';
import 'inventory_validator.dart';
import 'pole_placement_engine.dart';
import 'structural_graph_analyzer.dart';
import 'truss_optimizer.dart';

/// Central domain orchestrator for Mandap layout calculations.
class MandapCalculationEngine {
  final PolePlacementEngine poleEngine;

  const MandapCalculationEngine({
    this.poleEngine = const PolePlacementEngine(),
  });

  /// Executes full deterministic calculation pipeline for [layout].
  MandapCalculationResult calculate({
    required MandapLayout layout,
    required TrussCatalog catalog,
    required TrussInventory inventory,
  }) {
    final warnings = <String>[];

    // 1. Validate graph layout integrity
    final layoutIssues = layout.validate();

    // 2. Solve truss piece decomposition per edge
    final edgeSolutions = <EdgeId, EdgeSolution>{};
    for (final edge in layout.edges.values) {
      final startNode = layout.nodes[edge.startNodeId];
      final endNode = layout.nodes[edge.endNodeId];
      if (startNode != null && endNode != null) {
        try {
          edge.calculateGeometricLength(startNode, endNode);
        } catch (_) {
          warnings.add(
            'Edge ${edge.id} has a diagonal length that is not a 0.5 ft increment — '
            'adjust node positions to axis-aligned or 0.5 ft snap for truss calculation.',
          );
        }
      }

      try {
        final length = layout.getEdgeLength(edge);
        final sol = TrussOptimizer.solveEdge(
          edgeId: edge.id,
          targetLength: length,
          catalog: catalog,
        );
        edgeSolutions[edge.id] = sol;

        if (!sol.exactFit) {
          warnings.add(
            'Edge ${edge.id} ($length) cannot be constructed exactly with catalog pieces. '
            'Nearest feasible lower: ${sol.nearestLower ?? "N/A"}, higher: ${sol.nearestHigher ?? "N/A"}.',
          );
        }
      } on ArgumentError {
        warnings.add(
          'Edge ${edge.id} has a diagonal length that is not a 0.5 ft increment — '
          'adjust node positions to axis-aligned or 0.5 ft snap for truss calculation.',
        );
      }
    }

    // 3. Aggregate Bill of Materials (BOM)
    final requiredBOM = InventoryValidator.aggregateBOM(
      edgeSolutions.values.toList(),
    );

    // 4. Validate inventory stock & detect shortages
    final shortages = InventoryValidator.validateStock(
      requiredBOM: requiredBOM,
      inventory: inventory,
    );

    for (final shortage in shortages) {
      warnings.add(
        'Stock shortage for ${shortage.pieceType.name}: Required ${shortage.requiredCount}, '
        'Available ${shortage.availableCount} (Shortage: ${shortage.shortageCount}).',
      );
    }

    // 5. Calculate vertical support poles
    final poles = poleEngine.calculatePoles(layout);

    // 6. Run pure structural graph analysis
    final structuralReport = StructuralGraphAnalyzer.analyze(
      layout,
      preferredSpacingFeet: poleEngine.maxSpanFeet,
    );
    warnings.addAll(structuralReport.warnings);

    // 7. Calculate Totals
    double totalTrussLengthFt = 0.0;
    for (final entry in requiredBOM.entries) {
      totalTrussLengthFt += entry.key.length.feet * entry.value;
    }

    double totalFlooringAreaSqFt = 0.0;
    double totalStageAreaSqFt = 0.0;
    for (final zone in layout.zones) {
      final area = zone.width * zone.height;
      if (zone.type == ZoneType.flooring) {
        totalFlooringAreaSqFt += area;
      } else if (zone.type == ZoneType.stage) {
        totalStageAreaSqFt += area;
      }
    }

    return MandapCalculationResult(
      layoutIssues: List.unmodifiable(layoutIssues),
      edgeSolutions: Map.unmodifiable(edgeSolutions),
      requiredTrussBySize: requiredBOM,
      poles: poles,
      inventoryShortages: shortages,
      warnings: List.unmodifiable(warnings),
      structuralReport: structuralReport,
      totalTrussLengthFt: totalTrussLengthFt,
      totalFlooringAreaSqFt: totalFlooringAreaSqFt,
      totalStageAreaSqFt: totalStageAreaSqFt,
    );
  }
}
