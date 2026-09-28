import 'dart:math' as math;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to adjust the interactive center structural control point / junction
/// freely in all directions (X-axis left/right and Z-axis front/back / up/down),
/// dynamically repositioning boundary connection nodes along the perimeter walls
/// and recalculating intermediate support poles along cross members (>40ft rule).
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
  MandapLayout? _previousLayout;

  AdjustCenterPositionCommand({
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
    _previousLayout = currentLayout;

    final centerNode = currentLayout.getNode(centerNodeId);
    if (centerNode == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);

    // 1. Move center junction node in all directions (X and Z)
    updatedNodes[centerNodeId] = centerNode.copyWith(
      x: newX,
      z: newZ,
      support: NodeSupport.pole,
      type: NodeType.junction,
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

    // 3. Remove previous cross edges and intermediate cross sub-nodes
    updatedNodes.removeWhere((id, n) => id.value.contains('sub_cross') || id.value.contains('n_sub_'));
    updatedEdges.removeWhere((id, e) => id.value.contains('cross'));

    // 4. Subdivide cross arms and place support poles when distance > 40 ft
    final armDefinitions = [
      if (resolvedNorth != null && updatedNodes.containsKey(resolvedNorth)) (boundaryId: resolvedNorth, tag: 'cross_north'),
      if (resolvedEast != null && updatedNodes.containsKey(resolvedEast)) (boundaryId: resolvedEast, tag: 'cross_east'),
      if (resolvedSouth != null && updatedNodes.containsKey(resolvedSouth)) (boundaryId: resolvedSouth, tag: 'cross_south'),
      if (resolvedWest != null && updatedNodes.containsKey(resolvedWest)) (boundaryId: resolvedWest, tag: 'cross_west'),
    ];

    for (final arm in armDefinitions) {
      final bNode = updatedNodes[arm.boundaryId]!;
      final cNode = updatedNodes[centerNodeId]!;

      final chain = <NodeId>[arm.boundaryId];
      final poleLocs = _computeArmPoleLocations(
        bNode: bNode,
        cNode: cNode,
        allNodes: updatedNodes,
        preferredSpacing: 30.0,
      );

      for (final loc in poleLocs) {
        final subX = loc.x;
        final subZ = loc.z;

        final subId = NodeId('n_sub_${arm.tag}_${subX.toInt()}_${subZ.toInt()}');
        updatedNodes[subId] = MandapNode(
          id: subId,
          x: subX,
          z: subZ,
          elevation: centerNode.elevation,
          height: centerNode.height,
          type: NodeType.pole,
          support: NodeSupport.pole,
          structureId: 'main',
        );

        chain.add(subId);
      }

      chain.add(centerNodeId);

      for (int i = 0; i < chain.length - 1; i++) {
        final eId = EdgeId('e_${arm.tag}_$i');
        updatedEdges[eId] = MandapEdge(
          id: eId,
          startNodeId: chain[i],
          endNodeId: chain[i + 1],
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    return _previousLayout ?? currentLayout;
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

    // Check existing cross edges first to find boundary connection nodes
    for (final edge in layout.edges.values) {
      if (edge.id.value.contains('cross')) {
        final sn = layout.getNode(edge.startNodeId);
        final en = layout.getNode(edge.endNodeId);
        for (final node in [sn, en]) {
          if (node != null && node.id != centerNodeId && !node.id.value.contains('sub')) {
            if ((node.z - minZ).abs() < 1.0 && node.x > minX + 1.0 && node.x < maxX - 1.0) nId = node.id;
            if ((node.z - maxZ).abs() < 1.0 && node.x > minX + 1.0 && node.x < maxX - 1.0) sId = node.id;
            if ((node.x - minX).abs() < 1.0 && node.z > minZ + 1.0 && node.z < maxZ - 1.0) wId = node.id;
            if ((node.x - maxX).abs() < 1.0 && node.z > minZ + 1.0 && node.z < maxZ - 1.0) eId = node.id;
          }
        }
      }
    }

    // Fallback search along perimeter walls closest to (oldX, oldZ)
    for (final n in layout.nodes.values) {
      if (n.id == centerNodeId || n.isControlPoint || n.id.value.contains('sub') || n.type == NodeType.corner) continue;
      if ((n.z - minZ).abs() <= 1.0 && n.x > minX + 1.0 && n.x < maxX - 1.0) {
        if (nId == null || (n.x - oldX).abs() < (layout.getNode(nId)!.x - oldX).abs()) {
          nId = n.id;
        }
      }
      if ((n.z - maxZ).abs() <= 1.0 && n.x > minX + 1.0 && n.x < maxX - 1.0) {
        if (sId == null || (n.x - oldX).abs() < (layout.getNode(sId)!.x - oldX).abs()) {
          sId = n.id;
        }
      }
      if ((n.x - minX).abs() <= 1.0 && n.z > minZ + 1.0 && n.z < maxZ - 1.0) {
        if (wId == null || (n.z - oldZ).abs() < (layout.getNode(wId)!.z - oldZ).abs()) {
          wId = n.id;
        }
      }
      if ((n.x - maxX).abs() <= 1.0 && n.z > minZ + 1.0 && n.z < maxZ - 1.0) {
        if (eId == null || (n.z - oldZ).abs() < (layout.getNode(eId)!.z - oldZ).abs()) {
          eId = n.id;
        }
      }
    }

    return (nId, sId, wId, eId, minX, maxX, minZ, maxZ);
  }

  @override
  String get description =>
      'Adjust center position from (${oldX.toStringAsFixed(1)}, ${oldZ.toStringAsFixed(1)}) to (${newX.toStringAsFixed(1)}, ${newZ.toStringAsFixed(1)})';

  static List<({double x, double z})> _computeArmPoleLocations({
    required MandapNode bNode,
    required MandapNode cNode,
    required Map<NodeId, MandapNode> allNodes,
    required double preferredSpacing,
  }) {
    final double totalDist = math.sqrt(
      math.pow(cNode.x - bNode.x, 2) + math.pow(cNode.z - bNode.z, 2),
    );

    if (totalDist <= 40.0 + 0.5) {
      return const [];
    }

    final bool isAlongX = (bNode.z - cNode.z).abs() < 0.2;
    final bool isAlongZ = (bNode.x - cNode.x).abs() < 0.2;

    if (isAlongX) {
      final double minX = math.min(bNode.x, cNode.x);
      final double maxX = math.max(bNode.x, cNode.x);
      final bool goingPositive = cNode.x > bNode.x;

      final existingXs = allNodes.values
          .where((n) =>
              (n.support == NodeSupport.pole || n.type == NodeType.pole || n.type == NodeType.corner) &&
              !n.isControlPoint &&
              n.x > minX + 0.5 &&
              n.x < maxX - 0.5)
          .map((n) => double.parse(n.x.toStringAsFixed(1)))
          .toSet()
          .toList()
        ..sort();

      if (existingXs.isNotEmpty) {
        final selectedXs = <double>[];
        double prevX = bNode.x;
        final sortedXs = goingPositive ? existingXs : existingXs.reversed.toList();

        for (final candX in sortedXs) {
          final distFromPrev = (candX - prevX).abs();
          final distToEnd = (cNode.x - candX).abs();
          if (distFromPrev > 0.5 && distFromPrev <= 40.0 + 0.5) {
            selectedXs.add(candX);
            prevX = candX;
            if (distToEnd <= 40.0 + 0.5) {
              break;
            }
          }
        }

        final finalSpan = (cNode.x - prevX).abs();
        if (finalSpan <= 40.0 + 0.5 && selectedXs.isNotEmpty) {
          return selectedXs.map((x) => (x: x, z: bNode.z)).toList();
        }
      }

      final spacing = (preferredSpacing > 0 && preferredSpacing <= 40.0) ? preferredSpacing : 30.0;
      final gridPoints = <double>[];
      double curr = bNode.x;
      while (true) {
        final remaining = (cNode.x - curr).abs();
        if (remaining <= 40.0 + 0.5) break;
        curr += goingPositive ? spacing : -spacing;
        gridPoints.add(curr);
      }
      return gridPoints.map((x) => (x: x, z: bNode.z)).toList();
    }

    if (isAlongZ) {
      final double minZ = math.min(bNode.z, cNode.z);
      final double maxZ = math.max(bNode.z, cNode.z);
      final bool goingPositive = cNode.z > bNode.z;

      final existingZs = allNodes.values
          .where((n) =>
              (n.support == NodeSupport.pole || n.type == NodeType.pole || n.type == NodeType.corner) &&
              !n.isControlPoint &&
              n.z > minZ + 0.5 &&
              n.z < maxZ - 0.5)
          .map((n) => double.parse(n.z.toStringAsFixed(1)))
          .toSet()
          .toList()
        ..sort();

      if (existingZs.isNotEmpty) {
        final selectedZs = <double>[];
        double prevZ = bNode.z;
        final sortedZs = goingPositive ? existingZs : existingZs.reversed.toList();

        for (final candZ in sortedZs) {
          final distFromPrev = (candZ - prevZ).abs();
          final distToEnd = (cNode.z - candZ).abs();
          if (distFromPrev > 0.5 && distFromPrev <= 40.0 + 0.5) {
            selectedZs.add(candZ);
            prevZ = candZ;
            if (distToEnd <= 40.0 + 0.5) {
              break;
            }
          }
        }

        final finalSpan = (cNode.z - prevZ).abs();
        if (finalSpan <= 40.0 + 0.5 && selectedZs.isNotEmpty) {
          return selectedZs.map((z) => (x: bNode.x, z: z)).toList();
        }
      }

      final spacing = (preferredSpacing > 0 && preferredSpacing <= 40.0) ? preferredSpacing : 30.0;
      final gridPoints = <double>[];
      double curr = bNode.z;
      while (true) {
        final remaining = (cNode.z - curr).abs();
        if (remaining <= 40.0 + 0.5) break;
        curr += goingPositive ? spacing : -spacing;
        gridPoints.add(curr);
      }
      return gridPoints.map((z) => (x: bNode.x, z: z)).toList();
    }

    // Non-orthogonal arm
    final spacing = (preferredSpacing > 0 && preferredSpacing <= 40.0) ? preferredSpacing : 30.0;
    final points = <({double x, double z})>[];
    double currentDist = spacing;
    while (totalDist - currentDist > 40.0 + 0.5) {
      final frac = currentDist / totalDist;
      points.add((
        x: bNode.x + (cNode.x - bNode.x) * frac,
        z: bNode.z + (cNode.z - bNode.z) * frac,
      ));
      currentDist += spacing;
    }
    return points;
  }
}
