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
  MandapLayout? _previousLayout;

  CreateCenterCrossCommand({
    required this.plotWidth,
    required this.plotDepth,
    this.elevation = 20.0,
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

    // Find all poles on North boundary (z ~ 0)
    final northPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.z - 0.0).abs() <= 1.0 &&
        isPoleNode(n)).toList();

    // Find all poles on South boundary (z ~ plotDepth)
    final southPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.z - plotDepth).abs() <= 1.0 &&
        isPoleNode(n)).toList();

    // Find all poles on West boundary (x ~ 0)
    final westPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.x - 0.0).abs() <= 1.0 &&
        isPoleNode(n)).toList();

    // Find all poles on East boundary (x ~ plotWidth)
    final eastPoles = nodes.values.where((n) =>
        !n.isControlPoint &&
        (n.x - plotWidth).abs() <= 1.0 &&
        isPoleNode(n)).toList();

    // If any side has no pole at all, cannot create cross
    if (northPoles.isEmpty || southPoles.isEmpty || westPoles.isEmpty || eastPoles.isEmpty) {
      return currentLayout;
    }

    // Pick closest pole to target on each side (prioritizing intermediate non-corner poles)
    MandapNode findBestPole(List<MandapNode> candidates, double targetCoord, bool isXAxis) {
      final intermediate = candidates.where((n) =>
          isXAxis ? (n.x > 1.0 && n.x < plotWidth - 1.0) : (n.z > 1.0 && n.z < plotDepth - 1.0)).toList();
      final pool = intermediate.isNotEmpty ? intermediate : candidates;
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

    final crossEdges = [
      (startId: northNodeId, endId: centerId, tag: 'cross_north'),
      (startId: eastNodeId, endId: centerId, tag: 'cross_east'),
      (startId: southNodeId, endId: centerId, tag: 'cross_south'),
      (startId: westNodeId, endId: centerId, tag: 'cross_west'),
    ];

    for (final item in crossEdges) {
      final eId = EdgeId('e_${item.tag}');
      edges[eId] = MandapEdge(
        id: eId,
        startNodeId: item.startId,
        endNodeId: item.endId,
        profile: EdgeProfile.box,
        role: TrussMemberRole.upper,
      );
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
}