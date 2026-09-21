import '../entities/edge_id.dart';
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../value_objects/truss_bom_summary.dart';

/// Pure domain service that deterministically calculates the separate
/// Pillar/Vertical Truss and Upper/Horizontal/Roof Truss Bill of Materials (BOM)
/// from the authoritative [MandapLayout] geometry.
class TrussBomCalculator {
  const TrussBomCalculator();

  static const double tolerance = 0.001;

  /// Classifies an edge into [TrussMemberCategory.pillar] or [TrussMemberCategory.upper].
  ///
  /// Priority:
  /// 1. Explicit structural role: [TrussMemberRole.tower] -> pillar.
  /// 2. Explicit structural role: [TrussMemberRole.upper] or [TrussMemberRole.custom] -> upper.
  /// 3. Topology: Connected to [NodeType.controlPoint] -> upper (roof apex / internal cross).
  /// 4. Geometry direction fallback:
  ///    - Vertical (abs(dy) > tol AND abs(dx) <= tol AND abs(dz) <= tol) -> pillar.
  ///    - Otherwise (horizontal, sloped, or multi-axis) -> upper.
  TrussMemberCategory classifyEdge(MandapLayout layout, MandapEdge edge) {
    // 1. Explicit structural role
    if (edge.role == TrussMemberRole.tower) {
      return TrussMemberCategory.pillar;
    }
    if (edge.role == TrussMemberRole.upper || edge.role == TrussMemberRole.custom) {
      return TrussMemberCategory.upper;
    }

    final startNode = layout.getNode(edge.startNodeId);
    final endNode = layout.getNode(edge.endNodeId);
    if (startNode == null || endNode == null) {
      return TrussMemberCategory.upper;
    }

    // 2. Topology: Center control point / roof apex connections are always Upper
    if (startNode.isControlPoint ||
        endNode.isControlPoint ||
        startNode.type == NodeType.controlPoint ||
        endNode.type == NodeType.controlPoint) {
      return TrussMemberCategory.upper;
    }

    // 3. World-space geometric displacement fallback
    final dx = (endNode.x - startNode.x).abs();
    final dy = (endNode.elevation - startNode.elevation).abs();
    final dz = (endNode.z - startNode.z).abs();

    if (dy > tolerance && dx <= tolerance && dz <= tolerance) {
      return TrussMemberCategory.pillar;
    }

    return TrussMemberCategory.upper;
  }

  /// Calculates the authoritative [TrussBomSummary] for [layout].
  TrussBomSummary calculateBom(MandapLayout layout) {
    final countedEdges = <EdgeId>{};
    final pillarItems = <TrussMemberBomItem>[];
    final upperItems = <TrussMemberBomItem>[];

    double pillarFt = 0.0;
    double upperFt = 0.0;

    // Iterate through all actual structural edges in layout
    for (final edge in layout.edges.values) {
      // Prevent double-counting: each edge is classified and counted exactly once
      if (countedEdges.contains(edge.id)) continue;
      countedEdges.add(edge.id);

      final length = layout.get3DGeometricLengthFeet(edge);
      final category = classifyEdge(layout, edge);

      final item = TrussMemberBomItem(
        edgeId: edge.id.value,
        category: category,
        lengthFeet: length,
      );

      if (category == TrussMemberCategory.pillar) {
        pillarItems.add(item);
        pillarFt += length;
      } else {
        upperItems.add(item);
        upperFt += length;
      }
    }

    return TrussBomSummary(
      pillarQuantity: pillarItems.length,
      pillarTotalFeet: pillarFt,
      upperQuantity: upperItems.length,
      upperTotalFeet: upperFt,
      totalQuantity: pillarItems.length + upperItems.length,
      totalFeet: pillarFt + upperFt,
      pillarMembers: List.unmodifiable(pillarItems),
      upperMembers: List.unmodifiable(upperItems),
    );
  }
}
