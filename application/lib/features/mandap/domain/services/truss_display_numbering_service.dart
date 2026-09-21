import 'dart:math' as math;
import '../entities/edge_id.dart';
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/node_id.dart';

/// Result container holding immutable dynamic display number mappings for nodes and edges.
class TrussDisplayNumberingResult {
  final Map<NodeId, int> nodeNumbers;
  final Map<EdgeId, int> edgeNumbers;

  const TrussDisplayNumberingResult({
    this.nodeNumbers = const {},
    this.edgeNumbers = const {},
  });

  int? getNodeNumber(NodeId id) => nodeNumbers[id];
  int? getEdgeNumber(EdgeId id) => edgeNumbers[id];
}

/// Pure, deterministic domain presentation service that computes dynamic 1-based display numbers
/// for structural nodes and edges based on their current world-space coordinates.
///
/// Disassociates dynamic display numbering from immutable structural IDs (NodeId/EdgeId).
///
/// Invariants:
/// - NodeId and EdgeId remain strictly immutable.
/// - Display numbers are derived deterministically from the current authoritative [MandapLayout].
/// - Parity: 2D and 3D views consume the exact same numbers.
/// - Camera operations (orbit, pan, zoom) never mutate or reorder display numbers.
class TrussDisplayNumberingService {
  const TrussDisplayNumberingService();

  /// Computes both node and edge display numbers for [layout].
  TrussDisplayNumberingResult computeNumbering(MandapLayout layout) {
    return TrussDisplayNumberingResult(
      nodeNumbers: buildNodeNumbers(layout),
      edgeNumbers: buildEdgeNumbers(layout),
    );
  }

  /// Computes deterministic 1-based display numbers for all structural nodes in [layout].
  ///
  /// Spatial ordering convention:
  /// Primary axis: Front -> Back (Z ascending)
  /// Secondary axis: Left -> Right (X ascending)
  /// Tertiary axis: Elevation (Y ascending)
  /// Tie-breaker: NodeId string comparison
  Map<NodeId, int> buildNodeNumbers(MandapLayout layout) {
    if (layout.nodes.isEmpty) return const {};

    // Filter to structural nodes only (exclude decorative/carpet/stage nodes)
    final structuralNodes = layout.nodes.values
        .where((n) => n.type != NodeType.stage && n.type != NodeType.carpet)
        .toList();

    const epsilon = 0.05; // 0.05 ft tolerance for row/column alignment

    structuralNodes.sort((a, b) {
      // 1. Z-axis: Front -> Back
      if ((a.z - b.z).abs() > epsilon) {
        return a.z.compareTo(b.z);
      }

      // 2. X-axis: Left -> Right
      if ((a.x - b.x).abs() > epsilon) {
        return a.x.compareTo(b.x);
      }

      // 3. Elevation: Bottom -> Top
      if ((a.elevation - b.elevation).abs() > epsilon) {
        return a.elevation.compareTo(b.elevation);
      }

      // 4. Stable tie-breaker: NodeId string comparison
      return a.id.value.compareTo(b.id.value);
    });

    final result = <NodeId, int>{};
    for (int i = 0; i < structuralNodes.length; i++) {
      result[structuralNodes[i].id] = i + 1;
    }
    return Map.unmodifiable(result);
  }

  /// Computes deterministic 1-based display numbers for all structural edges in [layout].
  ///
  /// Spatial ordering convention:
  /// Primary axis: Midpoint Front -> Back (midZ ascending)
  /// Secondary axis: Midpoint Left -> Right (midX ascending)
  /// Tertiary axis: Midpoint Elevation (midY ascending)
  /// Tie-breaker: EdgeId string comparison
  Map<EdgeId, int> buildEdgeNumbers(MandapLayout layout) {
    if (layout.edges.isEmpty) return const {};

    final upperEdges = <MandapEdge>[];
    final towerEdges = <MandapEdge>[];

    for (final edge in layout.edges.values) {
      final sNode = layout.getNode(edge.startNodeId);
      final eNode = layout.getNode(edge.endNodeId);
      final isTower = edge.role == TrussMemberRole.tower ||
          (sNode != null && eNode != null && sNode.x == eNode.x && sNode.z == eNode.z);
      if (isTower) {
        towerEdges.add(edge);
      } else {
        upperEdges.add(edge);
      }
    }

    const epsilon = 0.05;

    int compareEdges(MandapEdge a, MandapEdge b) {
      final aStart = layout.getNode(a.startNodeId);
      final aEnd = layout.getNode(a.endNodeId);
      final bStart = layout.getNode(b.startNodeId);
      final bEnd = layout.getNode(b.endNodeId);

      final aMidZ = ((aStart?.z ?? 0.0) + (aEnd?.z ?? 0.0)) / 2.0;
      final bMidZ = ((bStart?.z ?? 0.0) + (bEnd?.z ?? 0.0)) / 2.0;
      if ((aMidZ - bMidZ).abs() > epsilon) {
        return aMidZ.compareTo(bMidZ);
      }

      final aMidX = ((aStart?.x ?? 0.0) + (aEnd?.x ?? 0.0)) / 2.0;
      final bMidX = ((bStart?.x ?? 0.0) + (bEnd?.x ?? 0.0)) / 2.0;
      if ((aMidX - bMidX).abs() > epsilon) {
        return aMidX.compareTo(bMidX);
      }

      final aMidY = ((aStart?.elevation ?? 0.0) + (aEnd?.elevation ?? 0.0)) / 2.0;
      final bMidY = ((bStart?.elevation ?? 0.0) + (bEnd?.elevation ?? 0.0)) / 2.0;
      if ((aMidY - bMidY).abs() > epsilon) {
        return aMidY.compareTo(bMidY);
      }

      // If midpoints coincide, orient by start node coordinates
      final aMinZ = math.min(aStart?.z ?? 0.0, aEnd?.z ?? 0.0);
      final bMinZ = math.min(bStart?.z ?? 0.0, bEnd?.z ?? 0.0);
      if ((aMinZ - bMinZ).abs() > epsilon) {
        return aMinZ.compareTo(bMinZ);
      }

      final aMinX = math.min(aStart?.x ?? 0.0, aEnd?.x ?? 0.0);
      final bMinX = math.min(bStart?.x ?? 0.0, bEnd?.x ?? 0.0);
      if ((aMinX - bMinX).abs() > epsilon) {
        return aMinX.compareTo(bMinX);
      }

      // Stable tie-breaker: EdgeId string comparison
      return a.id.value.compareTo(b.id.value);
    }

    upperEdges.sort(compareEdges);
    towerEdges.sort(compareEdges);

    final result = <EdgeId, int>{};
    int counter = 1;
    for (final edge in upperEdges) {
      result[edge.id] = counter++;
    }
    for (final edge in towerEdges) {
      result[edge.id] = counter++;
    }
    return Map.unmodifiable(result);
  }
}
