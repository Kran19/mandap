import 'package:uuid/uuid.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/mandap_edge.dart';
import '../entities/node_id.dart';
import '../entities/edge_id.dart';
import '../specifications/component_specifications.dart';

class TrussGenerator {
  final Uuid _uuid = const Uuid();
  final Map<NodeId, MandapNode> _nodes = {};
  final Map<EdgeId, MandapEdge> _edges = {};

  MandapNode _addNode(double x, double y, double z, {NodeType type = NodeType.corner}) {
    final id = NodeId(_uuid.v4());
    final node = MandapNode(
      id: id,
      x: x,
      elevation: y,
      z: z,
      type: type,
    );
    _nodes[id] = node;
    return node;
  }

  MandapEdge _addEdge(NodeId start, NodeId end, {EdgeProfile profile = EdgeProfile.singleTube}) {
    final id = EdgeId(_uuid.v4());
    final edge = MandapEdge(
      id: id,
      startNodeId: start,
      endNodeId: end,
      profile: profile,
    );
    _edges[id] = edge;
    return edge;
  }

  MandapLayout generate(TrussSpecification spec) {
    _nodes.clear();
    _edges.clear();

    // 1. Generate Tower
    final towerConnectionNodes = _generateTower(spec);

    // 2. Generate Main Truss spanning through the tower
    _generateMainTruss(spec, towerConnectionNodes);

    // 3. Generate Roof Canopy Perimeter
    _generateRoof(spec);

    return MandapLayout(
      nodes: Map.from(_nodes),
      edges: Map.from(_edges),
      zones: const [],
    );
  }

  /// Generates the vertical tower and returns the explicit connection nodes
  Map<String, MandapNode> _generateTower(TrussSpecification spec) {
    final tHalfW = spec.towerWidth / 2.0;
    final tHalfD = spec.towerDepth / 2.0;
    final numSegments = (spec.height / spec.memberSegmentLength).ceil();
    final actualSegmentH = spec.height / numSegments;

    List<MandapNode> prevLevel = [];
    Map<String, MandapNode> connectionFrame = {};

    // For Tower Connection at roof elevation
    // Ensure we place an explicit frame at `spec.roofElevation`
    final Set<double> elevations = {};
    for (int i = 0; i <= numSegments; i++) elevations.add(i * actualSegmentH);
    elevations.add(spec.roofElevation);
    final sortedElevations = elevations.toList()..sort();

    for (int i = 0; i < sortedElevations.length; i++) {
      final y = sortedElevations[i];
      
      final fl = _addNode(-tHalfW, y, -tHalfD);
      final fr = _addNode( tHalfW, y, -tHalfD);
      final rl = _addNode(-tHalfW, y,  tHalfD);
      final rr = _addNode( tHalfW, y,  tHalfD);
      
      final currLevel = [fl, fr, rr, rl];

      // Rings
      for (int j = 0; j < 4; j++) {
        _addEdge(currLevel[j].id, currLevel[(j + 1) % 4].id);
      }

      // Bracing to previous level
      if (prevLevel.isNotEmpty) {
        for (int j = 0; j < 4; j++) {
          _addEdge(prevLevel[j].id, currLevel[j].id);
          _addEdge(prevLevel[j].id, currLevel[(j + 1) % 4].id);
        }
      }

      // Capture connection frame
      if ((y - spec.roofElevation).abs() < 0.001) {
        connectionFrame = {
          'TopFront': fl,
          'TopRear': rl,
          'BottomFront': fr,
          'BottomRear': rr,
        };
      }
      prevLevel = currLevel;
    }
    
    return connectionFrame;
  }

  void _generateMainTruss(TrussSpecification spec, Map<String, MandapNode> towerFrame) {
    // Top-front and Top-rear from the tower
    final topFront = towerFrame['TopFront']!;
    final topRear = towerFrame['TopRear']!;
    
    // Main Truss ends
    final leftEndTopFront = _addNode(-spec.width / 2.0, spec.roofElevation, -spec.towerDepth / 2.0);
    final leftEndTopRear = _addNode(-spec.width / 2.0, spec.roofElevation, spec.towerDepth / 2.0);
    
    final rightEndTopFront = _addNode(spec.width / 2.0, spec.roofElevation, -spec.towerDepth / 2.0);
    final rightEndTopRear = _addNode(spec.width / 2.0, spec.roofElevation, spec.towerDepth / 2.0);

    // Edges connecting to the explicit tower nodes (using SINGLE_TUBE for actual physical lattice, or BOX if abstracting)
    // Here we use singleTube since we explicitly model the tower.
    _addEdge(leftEndTopFront.id, topFront.id, profile: EdgeProfile.singleTube);
    _addEdge(leftEndTopRear.id, topRear.id, profile: EdgeProfile.singleTube);
    
    _addEdge(topFront.id, rightEndTopFront.id, profile: EdgeProfile.singleTube);
    _addEdge(topRear.id, rightEndTopRear.id, profile: EdgeProfile.singleTube);
    
    // We would also generate the bottom chords and X bracing for the main truss...
  }

  void _generateRoof(TrussSpecification spec) {
    final y = spec.roofElevation;
    final halfW = spec.width / 2.0;
    final halfD = spec.depth / 2.0;
    final towerHW = spec.towerWidth / 2.0;

    if (spec.configuration == TrussConfiguration.fivePoint) {
      // P1: Left outer
      final p1Front = _addNode(-halfW, y, -halfD);
      final p1Rear = _addNode(-halfW, y, halfD);
      // P2: Left main connection
      final p2Front = _addNode(-towerHW, y, -halfD);
      final p2Rear = _addNode(-towerHW, y, halfD);
      // P3: Center apex
      final p3Front = _addNode(0, y, -halfD);
      final p3Rear = _addNode(0, y, halfD);
      // P4: Right main connection
      final p4Front = _addNode(towerHW, y, -halfD);
      final p4Rear = _addNode(towerHW, y, halfD);
      // P5: Right outer
      final p5Front = _addNode(halfW, y, -halfD);
      final p5Rear = _addNode(halfW, y, halfD);

      // Front Perimeter
      _addEdge(p1Front.id, p2Front.id, profile: EdgeProfile.box);
      _addEdge(p2Front.id, p3Front.id, profile: EdgeProfile.box);
      _addEdge(p3Front.id, p4Front.id, profile: EdgeProfile.box);
      _addEdge(p4Front.id, p5Front.id, profile: EdgeProfile.box);

      // Rear Perimeter
      _addEdge(p1Rear.id, p2Rear.id, profile: EdgeProfile.box);
      _addEdge(p2Rear.id, p3Rear.id, profile: EdgeProfile.box);
      _addEdge(p3Rear.id, p4Rear.id, profile: EdgeProfile.box);
      _addEdge(p4Rear.id, p5Rear.id, profile: EdgeProfile.box);

      // Depth trusses (Left and Right edges)
      _addEdge(p1Front.id, p1Rear.id, profile: EdgeProfile.box);
      _addEdge(p5Front.id, p5Rear.id, profile: EdgeProfile.box);
      
      // Internal depth members
      _addEdge(p2Front.id, p2Rear.id, profile: EdgeProfile.box);
      _addEdge(p3Front.id, p3Rear.id, profile: EdgeProfile.box);
      _addEdge(p4Front.id, p4Rear.id, profile: EdgeProfile.box);

    } else if (spec.configuration == TrussConfiguration.sixPoint) {
      // 6-point layout
      final p1F = _addNode(-halfW, y, -halfD);
      final p2F = _addNode(-halfW / 2, y, -halfD);
      final p3F = _addNode(0, y, -halfD);
      final p4F = _addNode(halfW / 2, y, -halfD);
      final p5F = _addNode(halfW, y, -halfD);
      final p6F = _addNode(0, y, -halfD - 5.0); // P6 as an awning/extension point

      final p1R = _addNode(-halfW, y, halfD);
      final p2R = _addNode(-halfW / 2, y, halfD);
      final p3R = _addNode(0, y, halfD);
      final p4R = _addNode(halfW / 2, y, halfD);
      final p5R = _addNode(halfW, y, halfD);
      final p6R = _addNode(0, y, halfD + 5.0);

      _addEdge(p1F.id, p2F.id, profile: EdgeProfile.box);
      _addEdge(p2F.id, p3F.id, profile: EdgeProfile.box);
      _addEdge(p3F.id, p4F.id, profile: EdgeProfile.box);
      _addEdge(p4F.id, p5F.id, profile: EdgeProfile.box);
      _addEdge(p3F.id, p6F.id, profile: EdgeProfile.box); // Awning

      _addEdge(p1R.id, p2R.id, profile: EdgeProfile.box);
      _addEdge(p2R.id, p3R.id, profile: EdgeProfile.box);
      _addEdge(p3R.id, p4R.id, profile: EdgeProfile.box);
      _addEdge(p4R.id, p5R.id, profile: EdgeProfile.box);
      _addEdge(p3R.id, p6R.id, profile: EdgeProfile.box); // Awning

      _addEdge(p1F.id, p1R.id, profile: EdgeProfile.box);
      _addEdge(p5F.id, p5R.id, profile: EdgeProfile.box);
    }
  }
}
