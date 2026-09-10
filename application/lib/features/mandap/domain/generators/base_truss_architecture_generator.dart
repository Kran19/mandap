import 'package:uuid/uuid.dart';
import '../entities/edge_id.dart';
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/node_id.dart';

/// Specification inputs for base truss generation.
class BaseTrussGenerationParams {
  final double plotWidth;
  final double plotDepth;
  final double preferredPoleSpacing;
  final double poleHeight;
  final bool includeCenterControlPoint;
  final List<double> availableTrussSizes;

  const BaseTrussGenerationParams({
    required this.plotWidth,
    required this.plotDepth,
    this.preferredPoleSpacing = 30.0,
    this.poleHeight = 20.0,
    this.includeCenterControlPoint = true,
    this.availableTrussSizes = const [10.0, 30.0, 50.0],
  });
}

/// Parametric generator that creates the initial authoritative structural architecture.
///
/// Example:
/// Plot = 100 × 100 ft, preferred pole spacing = 30 ft:
/// - Perimeter sides segmented as: 30 + 30 + 30 + 10 ft (400 ft perimeter)
/// - 4 corner poles + 12 intermediate perimeter poles = 16 perimeter poles
/// - Optional center control pole at (50, 50) = 17 total poles
/// - 4 internal cross members (50+50+50+50 = 200 ft) connecting center to midpoints
/// - Total initial truss length = 600 ft
/// - Cross midpoint nodes have `role: NodeRole.junction` and `support: NodeSupport.none` (0 extra poles)
class BaseTrussArchitectureGenerator {
  const BaseTrussArchitectureGenerator();

  static MandapLayout generate(BaseTrussGenerationParams params) {
    final w = params.plotWidth;
    final d = params.plotDepth;
    final s = params.preferredPoleSpacing;
    final h = params.poleHeight;

    final nodes = <NodeId, MandapNode>{};
    final edges = <EdgeId, MandapEdge>{};

    final midX = w / 2.0;
    final midZ = d / 2.0;

    // Helper to generate pole positions along a side of length L with spacing s,
    // inserting midpoint if center cross is enabled to split perimeter members.
    List<double> getPositionsAlongSide(double length, double midpoint, bool includeMid) {
      final posSet = <double>{0.0, length};
      var current = s;
      while (current < length - 0.01) {
        posSet.add(current);
        current += s;
      }
      if (includeMid) {
        posSet.add(midpoint);
      }
      final sorted = posSet.toList()..sort();
      return sorted;
    }

    final xPositions = getPositionsAlongSide(w, midX, params.includeCenterControlPoint);
    final zPositions = getPositionsAlongSide(d, midZ, params.includeCenterControlPoint);

    // Map coordinates to created MandapNode instances
    final coordToNode = <String, MandapNode>{};

    MandapNode getOrCreateNode(
      double x,
      double z, {
      required NodeType role,
      required NodeSupport support,
    }) {
      final key = '${x.toStringAsFixed(3)}_${z.toStringAsFixed(3)}';
      if (coordToNode.containsKey(key)) {
        return coordToNode[key]!;
      }

      final id = NodeId('n_${x.toInt()}_${z.toInt()}_${DateTime.now().microsecondsSinceEpoch % 100000}_${coordToNode.length}');
      final node = MandapNode(
        id: id,
        x: x,
        z: z,
        type: role,
        support: support,
        height: h,
        elevation: h,
        structureId: 'main',
      );
      nodes[id] = node;
      coordToNode[key] = node;
      return node;
    }

    // 1. Generate perimeter nodes:
    // Corners and regular spacing intervals have NodeSupport.pole.
    // Midpoint cross junctions that do not coincide with spacing poles have NodeSupport.none.
    // South side: Z = 0, X from 0 to W
    final southNodes = <MandapNode>[];
    for (final x in xPositions) {
      final isCorner = (x == 0.0 || x == w);
      final isMid = params.includeCenterControlPoint && ((x - midX).abs() < 0.001);
      final isSpacingPole = isCorner || (x % s < 0.001) || ((s - (x % s)).abs() < 0.001);
      final role = isCorner ? NodeType.corner : (isMid ? NodeType.junction : NodeType.perimeterPole);
      final support = isSpacingPole ? NodeSupport.pole : NodeSupport.none;
      southNodes.add(getOrCreateNode(x, 0.0, role: role, support: support));
    }

    // East side: X = W, Z from 0 to D
    final eastNodes = <MandapNode>[];
    for (final z in zPositions) {
      final isCorner = (z == 0.0 || z == d);
      final isMid = params.includeCenterControlPoint && ((z - midZ).abs() < 0.001);
      final isSpacingPole = isCorner || (z % s < 0.001) || ((s - (z % s)).abs() < 0.001);
      final role = isCorner ? NodeType.corner : (isMid ? NodeType.junction : NodeType.perimeterPole);
      final support = isSpacingPole ? NodeSupport.pole : NodeSupport.none;
      eastNodes.add(getOrCreateNode(w, z, role: role, support: support));
    }

    // North side: Z = D, X from W down to 0
    final northNodes = <MandapNode>[];
    for (final x in xPositions.reversed) {
      final isCorner = (x == 0.0 || x == w);
      final isMid = params.includeCenterControlPoint && ((x - midX).abs() < 0.001);
      final isSpacingPole = isCorner || (x % s < 0.001) || ((s - (x % s)).abs() < 0.001);
      final role = isCorner ? NodeType.corner : (isMid ? NodeType.junction : NodeType.perimeterPole);
      final support = isSpacingPole ? NodeSupport.pole : NodeSupport.none;
      northNodes.add(getOrCreateNode(x, d, role: role, support: support));
    }

    // West side: X = 0, Z from D down to 0
    final westNodes = <MandapNode>[];
    for (final z in zPositions.reversed) {
      final isCorner = (z == 0.0 || z == d);
      final isMid = params.includeCenterControlPoint && ((z - midZ).abs() < 0.001);
      final isSpacingPole = isCorner || (z % s < 0.001) || ((s - (z % s)).abs() < 0.001);
      final role = isCorner ? NodeType.corner : (isMid ? NodeType.junction : NodeType.perimeterPole);
      final support = isSpacingPole ? NodeSupport.pole : NodeSupport.none;
      westNodes.add(getOrCreateNode(0.0, z, role: role, support: support));
    }

    // 2. Connect perimeter members sequentially in a closed loop (16 members for 100x100)
    void connectChain(List<MandapNode> chain) {
      for (var i = 0; i < chain.length - 1; i++) {
        final start = chain[i];
        final end = chain[i + 1];
        if (start.id == end.id) continue;
        final edgeId = EdgeId('e_perim_${edges.length}_${start.id.value}_${end.id.value}');
        edges[edgeId] = MandapEdge(
          id: edgeId,
          startNodeId: start.id,
          endNodeId: end.id,
          profile: EdgeProfile.box,
        );
      }
    }

    connectChain(southNodes);
    connectChain(eastNodes);
    connectChain(northNodes);
    connectChain(westNodes);

    // 3. Center Control Point & Internal Cross
    if (params.includeCenterControlPoint) {
      final centerId = NodeId('n_center_${midX.toInt()}_${midZ.toInt()}');
      final centerNode = MandapNode(
        id: centerId,
        x: midX,
        z: midZ,
        type: NodeType.controlPoint,
        support: NodeSupport.pole,
        height: h,
        elevation: h,
        structureId: 'main',
      );
      nodes[centerId] = centerNode;

      // The 4 cross endpoints: reuse existing perimeter node if at that exact coordinate,
      // or create a new junction node with support: NodeSupport.none (perimeter supplies support).
      final southMid = getOrCreateNode(midX, 0.0, role: NodeType.junction, support: NodeSupport.none);
      final eastMid = getOrCreateNode(w, midZ, role: NodeType.junction, support: NodeSupport.none);
      final northMid = getOrCreateNode(midX, d, role: NodeType.junction, support: NodeSupport.none);
      final westMid = getOrCreateNode(0.0, midZ, role: NodeType.junction, support: NodeSupport.none);

      final internalEndpoints = [southMid, eastMid, northMid, westMid];
      for (var i = 0; i < internalEndpoints.length; i++) {
        final endpoint = internalEndpoints[i];
        final crossEdgeId = EdgeId('e_internal_cross_$i');
        edges[crossEdgeId] = MandapEdge(
          id: crossEdgeId,
          startNodeId: centerNode.id,
          endNodeId: endpoint.id,
          profile: EdgeProfile.box,
        );
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(nodes),
      edges: Map.unmodifiable(edges),
      zones: const [],
    );
  }
}
