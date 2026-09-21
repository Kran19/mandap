import 'dart:math' as math;
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to adjust the interactive center structural control point / junction
/// freely in all directions (X-axis left/right and Z-axis front/back / up/down),
/// dynamically repositioning boundary connection nodes along the perimeter walls
/// while preserving straight perimeter boundaries and structure integrity.
class AdjustCenterPositionCommand implements MandapCommand {
  final NodeId centerNodeId;
  final double oldX;
  final double oldZ;
  final double newX;
  final double newZ;
  final NodeId? northMidNodeId;
  final NodeId? southMidNodeId;
  final NodeId? westMidNodeId;
  final NodeId? eastMidNodeId;

  const AdjustCenterPositionCommand({
    required this.centerNodeId,
    required this.oldX,
    required this.oldZ,
    required this.newX,
    required this.newZ,
    this.northMidNodeId,
    this.southMidNodeId,
    this.westMidNodeId,
    this.eastMidNodeId,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final centerNode = currentLayout.getNode(centerNodeId);
    if (centerNode == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);

    // 1. Move center junction node in all directions (X and Z)
    updatedNodes[centerNodeId] = centerNode.copyWith(
      x: newX,
      z: newZ,
    );

    // 2. Resolve boundary midpoint nodes connected to center
    final (nId, sId, wId, eId, minX, maxX, minZ, maxZ) = _findBoundaryNodes(currentLayout);

    final resolvedNorth = northMidNodeId ?? nId;
    final resolvedSouth = southMidNodeId ?? sId;
    final resolvedWest = westMidNodeId ?? wId;
    final resolvedEast = eastMidNodeId ?? eId;

    // North & South midpoints strictly track newX along their respective walls (Z fixed at boundary)
    if (resolvedNorth != null) {
      final northNode = currentLayout.getNode(resolvedNorth);
      if (northNode != null && northNode.type != NodeType.corner) {
        updatedNodes[resolvedNorth] = northNode.copyWith(x: newX, z: minZ);
      }
    }

    if (resolvedSouth != null) {
      final southNode = currentLayout.getNode(resolvedSouth);
      if (southNode != null && southNode.type != NodeType.corner) {
        updatedNodes[resolvedSouth] = southNode.copyWith(x: newX, z: maxZ);
      }
    }

    // West & East midpoints strictly track newZ along their respective walls (X fixed at boundary)
    if (resolvedWest != null) {
      final westNode = currentLayout.getNode(resolvedWest);
      if (westNode != null && westNode.type != NodeType.corner) {
        updatedNodes[resolvedWest] = westNode.copyWith(x: minX, z: newZ);
      }
    }

    if (resolvedEast != null) {
      final eastNode = currentLayout.getNode(resolvedEast);
      if (eastNode != null && eastNode.type != NodeType.corner) {
        updatedNodes[resolvedEast] = eastNode.copyWith(x: maxX, z: newZ);
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final centerNode = currentLayout.getNode(centerNodeId);
    if (centerNode == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);

    // Restore center node to (oldX, oldZ)
    updatedNodes[centerNodeId] = centerNode.copyWith(
      x: oldX,
      z: oldZ,
    );

    final (nId, sId, wId, eId, minX, maxX, minZ, maxZ) = _findBoundaryNodes(currentLayout);

    final resolvedNorth = northMidNodeId ?? nId;
    final resolvedSouth = southMidNodeId ?? sId;
    final resolvedWest = westMidNodeId ?? wId;
    final resolvedEast = eastMidNodeId ?? eId;

    if (resolvedNorth != null) {
      final northNode = currentLayout.getNode(resolvedNorth);
      if (northNode != null && northNode.type != NodeType.corner) {
        updatedNodes[resolvedNorth] = northNode.copyWith(x: oldX, z: minZ);
      }
    }

    if (resolvedSouth != null) {
      final southNode = currentLayout.getNode(resolvedSouth);
      if (southNode != null && southNode.type != NodeType.corner) {
        updatedNodes[resolvedSouth] = southNode.copyWith(x: oldX, z: maxZ);
      }
    }

    if (resolvedWest != null) {
      final westNode = currentLayout.getNode(resolvedWest);
      if (westNode != null && westNode.type != NodeType.corner) {
        updatedNodes[resolvedWest] = westNode.copyWith(x: minX, z: oldZ);
      }
    }

    if (resolvedEast != null) {
      final eastNode = currentLayout.getNode(resolvedEast);
      if (eastNode != null && eastNode.type != NodeType.corner) {
        updatedNodes[resolvedEast] = eastNode.copyWith(x: maxX, z: oldZ);
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  (NodeId?, NodeId?, NodeId?, NodeId?, double, double, double, double) _findBoundaryNodes(MandapLayout layout) {
    NodeId? nId;
    NodeId? sId;
    NodeId? wId;
    NodeId? eId;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minZ = double.infinity;
    double maxZ = -double.infinity;

    for (final n in layout.nodes.values) {
      if (n.id == centerNodeId || n.isControlPoint || n.type == NodeType.stage || n.type == NodeType.carpet) continue;
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.z < minZ) minZ = n.z;
      if (n.z > maxZ) maxZ = n.z;
    }

    if (!minX.isFinite) minX = 0.0;
    if (!maxX.isFinite) maxX = 100.0;
    if (!minZ.isFinite) minZ = 0.0;
    if (!maxZ.isFinite) maxZ = 100.0;

    final centerNode = layout.getNode(centerNodeId);
    if (centerNode == null) return (nId, sId, wId, eId, minX, maxX, minZ, maxZ);

    for (final edge in layout.edges.values) {
      if (edge.startNodeId == centerNodeId || edge.endNodeId == centerNodeId) {
        final otherId = edge.startNodeId == centerNodeId ? edge.endNodeId : edge.startNodeId;
        final otherNode = layout.getNode(otherId);
        if (otherNode == null || otherNode.type == NodeType.corner) continue;

        final dx = (otherNode.x - centerNode.x).abs();
        final dz = (otherNode.z - centerNode.z).abs();

        if (dz >= dx) {
          // Vertical arm: North or South
          if (otherNode.z <= centerNode.z) {
            nId = otherId;
          } else {
            sId = otherId;
          }
        } else {
          // Horizontal arm: West or East
          if (otherNode.x <= centerNode.x) {
            wId = otherId;
          } else {
            eId = otherId;
          }
        }
      }
    }

    return (nId, sId, wId, eId, minX, maxX, minZ, maxZ);
  }

  @override
  String get description =>
      'Adjust center position from (${oldX.toStringAsFixed(1)}, ${oldZ.toStringAsFixed(1)}) to (${newX.toStringAsFixed(1)}, ${newZ.toStringAsFixed(1)})';
}
