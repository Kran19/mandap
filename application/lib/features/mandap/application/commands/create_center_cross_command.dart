import 'dart:math' as math;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to atomically create the real structural + cross on MandapLayout.
/// Splits boundary edges at midpoints if needed, creates the center apex node,
/// and connects 4 cross edges. Fully undoable.
class CreateCenterCrossCommand implements MandapCommand {
  final double plotWidth;
  final double plotDepth;
  final double elevation;
  final double preferredPoleSpacing;
  MandapLayout? _previousLayout;

  CreateCenterCrossCommand({
    required this.plotWidth,
    required this.plotDepth,
    this.elevation = 20.0,
    this.preferredPoleSpacing = 30.0,
  });

  @override
  String get description => 'Create Center Cross Structure';

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    _previousLayout = currentLayout;

    final nodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    final edges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);

    final targetX = plotWidth / 2.0;
    final targetZ = plotDepth / 2.0;

    bool isPoleNode(MandapNode n) =>
        n.support == NodeSupport.pole ||
        n.type == NodeType.corner ||
        n.type == NodeType.pole;

    // Determine actual layout bounds (minX, maxX, minZ, maxZ)
    double minX = 0.0, maxX = plotWidth, minZ = 0.0, maxZ = plotDepth;
    if (nodes.isNotEmpty) {
      final elevated = nodes.values.where((n) => isPoleNode(n) && !n.isControlPoint);
      final pool = elevated.isNotEmpty ? elevated : nodes.values;
      minX = pool.map((n) => n.x).reduce(math.min);
      maxX = pool.map((n) => n.x).reduce(math.max);
      minZ = pool.map((n) => n.z).reduce(math.min);
      maxZ = pool.map((n) => n.z).reduce(math.max);
    }

    // Find all poles on North boundary (z ~ minZ)
    final northPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.z - minZ).abs() <= 1.5 &&
        isPoleNode(n)).toList();

    // Find all poles on South boundary (z ~ maxZ)
    final southPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.z - maxZ).abs() <= 1.5 &&
        isPoleNode(n)).toList();

    // Find all poles on West boundary (x ~ minX)
    final westPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.x - minX).abs() <= 1.5 &&
        isPoleNode(n)).toList();

    // Find all poles on East boundary (x ~ maxX)
    final eastPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.x - maxX).abs() <= 1.5 &&
        isPoleNode(n)).toList();

    // If any of the 4 sides has no support pole at all, cannot create cross
    if (northPoles.isEmpty || southPoles.isEmpty || westPoles.isEmpty || eastPoles.isEmpty) {
      return currentLayout;
    }

    // Pick closest pole to target on each boundary wall
    MandapNode findBestPole(List<MandapNode> candidates, double targetCoord, bool isXAxis) {
      final pool = List<MandapNode>.from(candidates);
      pool.sort((a, b) {
        final distA = isXAxis ? (a.x - targetCoord).abs() : (a.z - targetCoord).abs();
        final distB = isXAxis ? (b.x - targetCoord).abs() : (b.z - targetCoord).abs();
        return distA.compareTo(distB);
      });
      return pool.first;
    }

    final northPole = findBestPole(northPoles, targetX, true);
    final southPole = findBestPole(southPoles, targetX, true);
    final westPole = findBestPole(westPoles, targetZ, false);
    final eastPole = findBestPole(eastPoles, targetZ, false);

    // Center X is aligned with North/South pole X (or closest to targetX)
    final double crossX;
    if ((northPole.x - southPole.x).abs() < 1.0) {
      crossX = northPole.x;
    } else {
      final distN = (northPole.x - targetX).abs();
      final distS = (southPole.x - targetX).abs();
      crossX = distN <= distS ? northPole.x : southPole.x;
    }

    // Center Z is aligned with West/East pole Z (or closest to targetZ)
    final double crossZ;
    if ((westPole.z - eastPole.z).abs() < 1.0) {
      crossZ = westPole.z;
    } else {
      final distW = (westPole.z - targetZ).abs();
      final distE = (eastPole.z - targetZ).abs();
      crossZ = distW <= distE ? westPole.z : eastPole.z;
    }

    // Remove any 2D-only un-elevated control point center dot if present
    nodes.removeWhere((id, n) => (n.x - targetX).abs() < 0.1 && (n.z - targetZ).abs() < 0.1 && n.type == NodeType.controlPoint);

    final centerId = NodeId('n_center_${crossX.toInt()}_${crossZ.toInt()}');
    nodes[centerId] = MandapNode(
      id: centerId,
      x: crossX,
      z: crossZ,
      elevation: elevation,
      height: elevation,
      type: NodeType.junction,
      support: NodeSupport.pole,
      structureId: 'main',
    );

    // Helper to find exact node at straight orthogonal intersection or create boundary node
    NodeId getOrCreateStraightBoundaryNode(double targetX, double targetZ, String sideLabel) {
      for (final n in nodes.values) {
        if ((n.x - targetX).abs() < 0.2 && (n.z - targetZ).abs() < 0.2 && n.id != centerId) {
          return n.id;
        }
      }

      // Check if an existing edge can be split at (targetX, targetZ)
      EdgeId? edgeToSplit;
      MandapNode? splitStart;
      MandapNode? splitEnd;

      for (final edge in edges.values) {
        final sn = nodes[edge.startNodeId];
        final en = nodes[edge.endNodeId];
        if (sn == null || en == null) continue;

        final minX = math.min(sn.x, en.x) - 0.2;
        final maxX = math.max(sn.x, en.x) + 0.2;
        final minZ = math.min(sn.z, en.z) - 0.2;
        final maxZ = math.max(sn.z, en.z) + 0.2;

        if (targetX >= minX && targetX <= maxX &&
            targetZ >= minZ && targetZ <= maxZ) {
          final dx = en.x - sn.x;
          final dz = en.z - sn.z;
          final lenSq = dx * dx + dz * dz;
          if (lenSq > 0.001) {
            final lineDist = ((dz * targetX - dx * targetZ + en.x * sn.z - en.z * sn.x).abs()) / math.sqrt(lenSq);
            if (lineDist < 0.2) {
              edgeToSplit = edge.id;
              splitStart = sn;
              splitEnd = en;
              break;
            }
          }
        }
      }

      final midId = NodeId('n_mid_${sideLabel}_${targetX.toInt()}_${targetZ.toInt()}');
      nodes[midId] = MandapNode(
        id: midId,
        x: targetX,
        z: targetZ,
        elevation: elevation,
        height: elevation,
        type: NodeType.junction,
        support: NodeSupport.none,
        structureId: 'main',
      );

      if (edgeToSplit != null && splitStart != null && splitEnd != null) {
        edges.remove(edgeToSplit);
        final e1 = EdgeId('e_split_${edgeToSplit.value}_1');
        final e2 = EdgeId('e_split_${edgeToSplit.value}_2');
        edges[e1] = MandapEdge(
          id: e1,
          startNodeId: splitStart.id,
          endNodeId: midId,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        edges[e2] = MandapEdge(
          id: e2,
          startNodeId: midId,
          endNodeId: splitEnd.id,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
      }

      return midId;
    }

    // Connect strictly straight orthogonal North, South, West, East arms
    final northNodeId = getOrCreateStraightBoundaryNode(crossX, 0.0, 'north');
    final southNodeId = getOrCreateStraightBoundaryNode(crossX, plotDepth, 'south');
    final westNodeId = getOrCreateStraightBoundaryNode(0.0, crossZ, 'west');
    final eastNodeId = getOrCreateStraightBoundaryNode(plotWidth, crossZ, 'east');

    final armDefinitions = [
      (boundaryId: northNodeId, tag: 'cross_north'),
      (boundaryId: eastNodeId, tag: 'cross_east'),
      (boundaryId: southNodeId, tag: 'cross_south'),
      (boundaryId: westNodeId, tag: 'cross_west'),
    ];

    final spacing = preferredPoleSpacing > 0 ? preferredPoleSpacing : 30.0;

    for (final arm in armDefinitions) {
      final bNode = nodes[arm.boundaryId]!;
      final cNode = nodes[centerId]!;

      final chain = <NodeId>[arm.boundaryId];
      final poleLocs = _computeArmPoleLocations(
        bNode: bNode,
        cNode: cNode,
        allNodes: nodes,
        preferredSpacing: preferredPoleSpacing,
      );

      for (final loc in poleLocs) {
        final subX = loc.x;
        final subZ = loc.z;

        // Find existing node or create one
        NodeId? existingSubId;
        for (final n in nodes.values) {
          if ((n.x - subX).abs() < 0.2 && (n.z - subZ).abs() < 0.2 && n.id != centerId) {
            existingSubId = n.id;
            nodes[n.id] = n.copyWith(
              support: NodeSupport.pole,
              type: n.type == NodeType.corner ? NodeType.corner : NodeType.pole,
            );
            break;
          }
        }

        final subNodeId = existingSubId ?? () {
          final id = NodeId('n_sub_${arm.tag}_${subX.toInt()}_${subZ.toInt()}');
          nodes[id] = MandapNode(
            id: id,
            x: subX,
            z: subZ,
            elevation: elevation,
            height: elevation,
            type: NodeType.pole,
            support: NodeSupport.pole,
            structureId: 'main',
          );
          return id;
        }();

        chain.add(subNodeId);
      }

      chain.add(centerId);

      // Connect consecutive nodes in chain with upper box truss edges
      for (int i = 0; i < chain.length - 1; i++) {
        final eId = EdgeId('e_${arm.tag}_$i');
        edges[eId] = MandapEdge(
          id: eId,
          startNodeId: chain[i],
          endNodeId: chain[i + 1],
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
      }
    }

    return MandapLayout(
      nodes: nodes,
      edges: edges,
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    return _previousLayout ?? currentLayout;
  }

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
          if (distFromPrev >= 15.0 && distFromPrev <= 40.0 + 0.5) {
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

      final gridPoints = <double>[];
      double curr = bNode.x;
      while (true) {
        final remaining = (cNode.x - curr).abs();
        if (remaining <= 40.0 + 0.5) break;
        final step = 40.0;
        curr += goingPositive ? step : -step;
        if ((cNode.x - curr).abs() <= 0.5) break;
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
          if (distFromPrev >= 15.0 && distFromPrev <= 40.0 + 0.5) {
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

      final gridPoints = <double>[];
      double curr = bNode.z;
      while (true) {
        final remaining = (cNode.z - curr).abs();
        if (remaining <= 40.0 + 0.5) break;
        final step = 40.0;
        curr += goingPositive ? step : -step;
        if ((cNode.z - curr).abs() <= 0.5) break;
        gridPoints.add(curr);
      }
      return gridPoints.map((z) => (x: bNode.x, z: z)).toList();
    }

    // Non-orthogonal arm
    final points = <({double x, double z})>[];
    double currentDist = 40.0;
    while (totalDist - currentDist > 40.0 + 0.5) {
      final frac = currentDist / totalDist;
      points.add((
        x: bNode.x + (cNode.x - bNode.x) * frac,
        z: bNode.z + (cNode.z - bNode.z) * frac,
      ));
      currentDist += 40.0;
    }
    return points;
  }
}