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

    final perimCandidates = updatedNodes.values.where((n) => (n.type == NodeType.corner || n.type == NodeType.perimeterPole) && n.elevation > 0);
    final targetElevation = perimCandidates.isNotEmpty ? perimCandidates.first.elevation : (centerNode.elevation > 0 ? centerNode.elevation : 20.0);

    // 1. Move center junction node in all directions (X and Z)
    updatedNodes[centerNodeId] = centerNode.copyWith(
      x: newX,
      z: newZ,
      elevation: targetElevation,
      height: targetElevation,
      support: NodeSupport.pole,
      type: NodeType.junction,
    );

    // 2. Find static perimeter plot bounds (minX, maxX, minZ, maxZ)
    double minX = double.infinity, maxX = -double.infinity;
    double minZ = double.infinity, maxZ = -double.infinity;
    for (final n in updatedNodes.values) {
      if (n.id == centerNodeId || n.isControlPoint || n.type == NodeType.stage || n.type == NodeType.carpet || n.id.value.contains('sub')) continue;
      if (n.type == NodeType.corner || n.type == NodeType.perimeterPole || n.type == NodeType.pole) {
        if (n.x < minX) minX = n.x;
        if (n.x > maxX) maxX = n.x;
        if (n.z < minZ) minZ = n.z;
        if (n.z > maxZ) maxZ = n.z;
      }
    }

    if (!minX.isFinite) minX = 0.0;
    if (!maxX.isFinite) maxX = 100.0;
    if (!minZ.isFinite) minZ = 0.0;
    if (!maxZ.isFinite) maxZ = 100.0;

    final double midX = (minX + maxX) / 2.0;
    final double midZ = (minZ + maxZ) / 2.0;

    // Clamp drag position strictly inside plot boundaries
    double safeCrossX = newX.clamp(minX + 2.0, maxX - 2.0);
    double safeCrossZ = newZ.clamp(minZ + 2.0, maxZ - 2.0);

    // Snap to exact plot midpoint when near center to maintain symmetry
    if ((safeCrossX - midX).abs() <= 3.0) safeCrossX = midX;
    if ((safeCrossZ - midZ).abs() <= 3.0) safeCrossZ = midZ;

    bool isBoundaryPole(MandapNode n) =>
        !n.isControlPoint &&
        n.id != centerNodeId &&
        n.type != NodeType.stage &&
        n.type != NodeType.carpet &&
        (n.support == NodeSupport.pole || n.type == NodeType.corner || n.type == NodeType.perimeterPole || n.type == NodeType.pole || n.type == NodeType.junction);

    final northCandidates = updatedNodes.values.where((n) => isBoundaryPole(n) && (n.z - minZ).abs() <= 1.5).toList();
    final southCandidates = updatedNodes.values.where((n) => isBoundaryPole(n) && (n.z - maxZ).abs() <= 1.5).toList();
    final westCandidates = updatedNodes.values.where((n) => isBoundaryPole(n) && (n.x - minX).abs() <= 1.5).toList();
    final eastCandidates = updatedNodes.values.where((n) => isBoundaryPole(n) && (n.x - maxX).abs() <= 1.5).toList();

    MandapNode? findClosest(List<MandapNode> candidates, double targetVal, bool isX) {
      if (candidates.isEmpty) return null;
      final sorted = List<MandapNode>.from(candidates);
      sorted.sort((a, b) {
        final dA = isX ? (a.x - targetVal).abs() : (a.z - targetVal).abs();
        final dB = isX ? (b.x - targetVal).abs() : (b.z - targetVal).abs();
        return dA.compareTo(dB);
      });
      return sorted.first;
    }

    // 1. Move center junction node smoothly to continuous drag position (safeCrossX, safeCrossZ) inside plot
    updatedNodes[centerNodeId] = centerNode.copyWith(
      x: safeCrossX,
      z: safeCrossZ,
      elevation: targetElevation,
      height: targetElevation,
      support: NodeSupport.pole,
      type: NodeType.junction,
    );

    // 2. Remove previous cross edges and intermediate cross sub-nodes
    updatedNodes.removeWhere((id, n) => id.value.contains('sub_cross') || id.value.contains('n_sub_') || id.value.contains('n_bound_') || id.value.contains('n_cross_'));
    updatedEdges.removeWhere((id, e) => id.value.contains('cross'));

    // 3. Connect straight arms to exact orthogonal boundary points on all 4 walls, reusing existing poles
    NodeId getBoundaryNode(double x, double z, String tag, List<MandapNode> wallCandidates, bool isXAxis) {
      final closest = findClosest(wallCandidates, isXAxis ? x : z, isXAxis);
      if (closest != null) {
        final dist = isXAxis ? (closest.x - x).abs() : (closest.z - z).abs();
        if (dist <= 3.5) {
          return closest.id;
        }
      }
      for (final n in wallCandidates) {
        if (updatedNodes.containsKey(n.id) && (n.x - x).abs() < 1.5 && (n.z - z).abs() < 1.5) {
          return n.id;
        }
      }
      final id = NodeId('n_cross_$tag');
      updatedNodes[id] = MandapNode(
        id: id,
        x: x,
        z: z,
        elevation: targetElevation,
        height: targetElevation,
        type: NodeType.pole,
        support: NodeSupport.pole,
        structureId: 'main',
      );
      return id;
    }

    final northBoundId = getBoundaryNode(safeCrossX, minZ, 'north', northCandidates, true);
    final southBoundId = getBoundaryNode(safeCrossX, maxZ, 'south', southCandidates, true);
    final westBoundId = getBoundaryNode(minX, safeCrossZ, 'west', westCandidates, false);
    final eastBoundId = getBoundaryNode(maxX, safeCrossZ, 'east', eastCandidates, false);

    final armDefinitions = [
      (boundaryId: northBoundId, tag: 'cross_north'),
      (boundaryId: eastBoundId, tag: 'cross_east'),
      (boundaryId: southBoundId, tag: 'cross_south'),
      (boundaryId: westBoundId, tag: 'cross_west'),
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

        NodeId? existingSubId;
        for (final n in updatedNodes.values) {
          final dx = n.x - subX;
          final dz = n.z - subZ;
          if ((dx * dx + dz * dz) <= 1.0 && n.id != centerNodeId) {
            existingSubId = n.id;
            updatedNodes[n.id] = n.copyWith(
              support: NodeSupport.pole,
              type: n.type == NodeType.corner ? NodeType.corner : NodeType.pole,
            );
            break;
          }
        }

        final subId = existingSubId ?? () {
          final id = NodeId('n_sub_${arm.tag}_${subX.toInt()}_${subZ.toInt()}');
          updatedNodes[id] = MandapNode(
            id: id,
            x: subX,
            z: subZ,
            elevation: targetElevation,
            height: targetElevation,
            type: NodeType.pole,
            support: NodeSupport.pole,
            structureId: 'main',
          );
          return id;
        }();

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

  void _resortPerimeterEdges({
    required Map<NodeId, MandapNode> nodes,
    required Map<EdgeId, MandapEdge> edges,
    required double minX,
    required double maxX,
    required double minZ,
    required double maxZ,
    required double targetElevation,
  }) {
    // 1. North Wall (z ≈ minZ)
    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.z - minZ).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(z: minZ, elevation: targetElevation, height: targetElevation),
      compare: (a, b) => a.x.compareTo(b.x),
    );

    // 2. South Wall (z ≈ maxZ)
    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.z - maxZ).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(z: maxZ, elevation: targetElevation, height: targetElevation),
      compare: (a, b) => a.x.compareTo(b.x),
    );

    // 3. West Wall (x ≈ minX)
    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.x - minX).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(x: minX, elevation: targetElevation, height: targetElevation),
      compare: (a, b) => a.z.compareTo(b.z),
    );

    // 4. East Wall (x ≈ maxX)
    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.x - maxX).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(x: maxX, elevation: targetElevation, height: targetElevation),
      compare: (a, b) => a.z.compareTo(b.z),
    );
  }

  void _reorderWallNodesAndEdges({
    required Map<NodeId, MandapNode> nodes,
    required Map<EdgeId, MandapEdge> edges,
    required bool Function(MandapNode n) isOnWall,
    required MandapNode Function(MandapNode n) clampToWall,
    required int Function(MandapNode a, MandapNode b) compare,
  }) {
    final wallNodes = <MandapNode>[];
    for (final entry in nodes.entries) {
      if (isOnWall(entry.value)) {
        final clamped = clampToWall(entry.value);
        nodes[entry.key] = clamped;
        wallNodes.add(clamped);
      }
    }

    if (wallNodes.length < 2) return;

    wallNodes.sort(compare);

    final wallNodeIds = wallNodes.map((n) => n.id).toSet();
    final wallEdgeKeys = <EdgeId>[];
    for (final entry in edges.entries) {
      if (wallNodeIds.contains(entry.value.startNodeId) &&
          wallNodeIds.contains(entry.value.endNodeId)) {
        wallEdgeKeys.add(entry.key);
      }
    }

    if (wallEdgeKeys.length == wallNodes.length - 1) {
      for (int i = 0; i < wallNodes.length - 1; i++) {
        final edgeId = wallEdgeKeys[i];
        final existingEdge = edges[edgeId]!;
        edges[edgeId] = existingEdge.copyWith(
          startNodeId: wallNodes[i].id,
          endNodeId: wallNodes[i + 1].id,
        );
      }
    } else if (wallEdgeKeys.isNotEmpty) {
      // If edge count differs, re-assign available wall edges to consecutive pairs
      for (int i = 0; i < math.min(wallEdgeKeys.length, wallNodes.length - 1); i++) {
        final edgeId = wallEdgeKeys[i];
        final existingEdge = edges[edgeId]!;
        edges[edgeId] = existingEdge.copyWith(
          startNodeId: wallNodes[i].id,
          endNodeId: wallNodes[i + 1].id,
        );
      }
    }
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
