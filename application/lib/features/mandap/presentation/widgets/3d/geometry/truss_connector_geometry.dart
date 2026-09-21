import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/mandap_layout.dart';
import '../../../../domain/entities/mandap_node.dart';
import 'truss_member_geometry.dart';

/// Pure, deterministic generator that creates modular corner/junction connector blocks
/// derived strictly from authoritative node topology in [MandapLayout].
///
/// Invariant:
/// Never invents fake junctions. Connectors are only created at actual [MandapNode]
/// locations where multiple structural members or a tower and beam meet.
class TrussConnectorGeometryGenerator {
  const TrussConnectorGeometryGenerator();

  /// Generates modular cube connectors for all structural junction nodes in [layout].
  Map<String, TrussConnectorCube> generateConnectors({
    required MandapLayout layout,
    double defaultHeight = 20.0,
  }) {
    final connectors = <String, TrussConnectorCube>{};

    for (final node in layout.nodes.values) {
      // Exclude decorative or non-structural nodes (e.g. stage, carpet)
      if (node.type == NodeType.stage || node.type == NodeType.carpet) {
        continue;
      }

      // Count structural edges connected directly to this node
      final connectedEdges = layout.edges.values.where(
        (e) => e.startNodeId == node.id || e.endNodeId == node.id,
      );

      final isCornerOrJunctionType = node.type == NodeType.corner ||
          node.type == NodeType.junction ||
          node.type == NodeType.generatedSupport;

      // Only generate connector if actual topology confirms a structural intersection
      final isJunctionNode = connectedEdges.length >= 2 ||
          isCornerOrJunctionType ||
          (connectedEdges.length >= 1 && node.elevation > 0);

      if (!isJunctionNode) continue;

      final elev = node.elevation > 0 ? node.elevation : defaultHeight;
      const jSize = 0.52; // Matches boxTrussVisualWidthFeet / 2 + 0.02

      final jBase = [
        v64.Vector3(node.x - jSize, elev - jSize, node.z - jSize),
        v64.Vector3(node.x + jSize, elev - jSize, node.z - jSize),
        v64.Vector3(node.x + jSize, elev - jSize, node.z + jSize),
        v64.Vector3(node.x - jSize, elev - jSize, node.z + jSize),
      ];

      final jTop = jBase.map((v) => v64.Vector3(v.x, v.y + jSize * 2, v.z)).toList();

      connectors[node.id.value] = TrussConnectorCube(
        nodeId: node.id,
        center: v64.Vector3(node.x, elev, node.z),
        halfExtent: jSize,
        baseCorners: jBase,
        topCorners: jTop,
      );
    }

    return Map.unmodifiable(connectors);
  }
}
