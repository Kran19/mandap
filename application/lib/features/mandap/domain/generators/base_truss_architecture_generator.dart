import '../entities/edge_id.dart';
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/node_id.dart';
import '../../../truss_boundary/domain/entities/boundary_truss_run.dart';
import '../../../truss_boundary/domain/entities/truss_size.dart';
import '../../../truss_boundary/domain/services/initial_boundary_pattern_service.dart';
import '../../../truss_boundary/domain/services/truss_pole_requirement_service.dart';

/// Specification inputs for base truss generation.
class BaseTrussGenerationParams {
  final double plotWidth;
  final double plotDepth;
  final double preferredPoleSpacing;
  final double poleHeight;
  final bool includeCenterControlPoint;
  final List<double> availableTrussSizes;
  final bool includeTowerEdges;
  final bool generateModularBayGrid;

  final List<double>? customPieceSequence;

  const BaseTrussGenerationParams({
    required this.plotWidth,
    required this.plotDepth,
    this.preferredPoleSpacing = 30.0,
    this.poleHeight = 20.0,
    this.includeCenterControlPoint = false,
    this.availableTrussSizes = const [10.0, 30.0, 50.0],
    this.includeTowerEdges = false,
    this.generateModularBayGrid = false,
    this.customPieceSequence,
  });
}

/// Parametric generator that creates the authoritative structural architecture.
/// 
/// Initial generation creates ONLY the four perimeter boundary walls (North, East, South, West).
class BaseTrussArchitectureGenerator {
  const BaseTrussArchitectureGenerator();

  static MandapLayout generate(BaseTrussGenerationParams params) {
    return _generateFourPerimeterSides(params);
  }

  /// Generates ONLY the four perimeter boundary walls according to the authoritative
  /// initial boundary patterns (e.g. 60 + 30 + 10 for 30ft on 100x100).
  static MandapLayout _generateFourPerimeterSides(BaseTrussGenerationParams params) {
    final w = params.plotWidth;
    final d = params.plotDepth;
    final h = params.poleHeight > 0 ? params.poleHeight : 20.0;
    final trussSize = TrussSize.fromLength(params.preferredPoleSpacing);

    final nodes = <NodeId, MandapNode>{};
    final edges = <EdgeId, MandapEdge>{};

    // Generate pure perimeter side runs using domain pattern service
    final sides = InitialBoundaryPatternService.generateSides(
      initialTrussSize: trussSize,
      width: w,
      depth: d,
      customSequence: params.customPieceSequence,
    );

    final nodeMap = <String, NodeId>{};

    NodeId getOrCreateNode(double x, double z, {required bool isCorner, bool isSupportPole = false}) {
      final key = x.toStringAsFixed(1) + '_' + z.toStringAsFixed(1);
      if (nodeMap.containsKey(key)) {
        final existingId = nodeMap[key]!;
        if (isCorner || isSupportPole) {
          final existing = nodes[existingId]!;
          nodes[existingId] = existing.copyWith(
            type: isCorner ? NodeType.corner : existing.type,
            support: NodeSupport.pole,
          );
        }
        return existingId;
      }

      final id = NodeId(isCorner ? ('n_corner_' + x.toInt().toString() + '_' + z.toInt().toString()) : ('n_perim_' + x.toInt().toString() + '_' + z.toInt().toString()));
      final node = MandapNode(
        id: id,
        x: x,
        z: z,
        type: isCorner ? NodeType.corner : NodeType.perimeterPole,
        support: (isCorner || isSupportPole) ? NodeSupport.pole : NodeSupport.none,
        height: h,
        elevation: h,
        structureId: 'main',
      );

      nodes[id] = node;
      nodeMap[key] = id;
      return id;
    }

    final interval = TrussPoleRequirementService.getSectionsBeforeSupportPole(trussSize);
    final standardSpan = trussSize.spanInFeet;

    List<bool> calculateRunSupports(List<BoundaryTrussRun> runs) {
      return List.filled(runs.length, true);
    }

    // 1. North side (from (0,0) to (w,0) along X)
    if (sides.containsKey('north')) {
      final northRuns = sides['north']!.runs;
      final northSupports = calculateRunSupports(northRuns);
      double acc = 0.0;
      NodeId prev = getOrCreateNode(0.0, 0.0, isCorner: true, isSupportPole: true);
      for (int i = 0; i < northRuns.length; i++) {
        acc += northRuns[i].geometricSpan;
        final isEnd = (acc - w).abs() < 0.05 || acc >= w;
        final currentX = isEnd ? w : acc;
        final isSupport = northSupports[i];
        final curr = getOrCreateNode(currentX, 0.0, isCorner: isEnd, isSupportPole: isSupport || isEnd);
        final edgeId = EdgeId('e_north_' + i.toString());
        edges[edgeId] = MandapEdge(
          id: edgeId,
          startNodeId: prev,
          endNodeId: curr,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        prev = curr;
      }
    }

    // 2. East side (from (w,0) to (w,d) along Z)
    if (sides.containsKey('east')) {
      final eastRuns = sides['east']!.runs;
      final eastSupports = calculateRunSupports(eastRuns);
      double acc = 0.0;
      NodeId prev = getOrCreateNode(w, 0.0, isCorner: true, isSupportPole: true);
      for (int i = 0; i < eastRuns.length; i++) {
        acc += eastRuns[i].geometricSpan;
        final isEnd = (acc - d).abs() < 0.05 || acc >= d;
        final currentZ = isEnd ? d : acc;
        final isSupport = eastSupports[i];
        final curr = getOrCreateNode(w, currentZ, isCorner: isEnd, isSupportPole: isSupport || isEnd);
        final edgeId = EdgeId('e_east_' + i.toString());
        edges[edgeId] = MandapEdge(
          id: edgeId,
          startNodeId: prev,
          endNodeId: curr,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        prev = curr;
      }
    }

    // 3. South side (from (0,d) to (w,d) along +X)
    if (sides.containsKey('south')) {
      final southRuns = sides['south']!.runs;
      final southSupports = calculateRunSupports(southRuns);
      double acc = 0.0;
      NodeId prev = getOrCreateNode(0.0, d, isCorner: true, isSupportPole: true);
      for (int i = 0; i < southRuns.length; i++) {
        acc += southRuns[i].geometricSpan;
        final isEnd = (acc - w).abs() < 0.05 || acc >= w;
        final currentX = isEnd ? w : acc;
        final isSupport = southSupports[i];
        final curr = getOrCreateNode(currentX, d, isCorner: isEnd, isSupportPole: isSupport || isEnd);
        final edgeId = EdgeId('e_south_' + i.toString());
        edges[edgeId] = MandapEdge(
          id: edgeId,
          startNodeId: prev,
          endNodeId: curr,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        prev = curr;
      }
    }

    // 4. West side (from (0,0) to (0,d) along +Z)
    if (sides.containsKey('west')) {
      final westRuns = sides['west']!.runs;
      final westSupports = calculateRunSupports(westRuns);
      double acc = 0.0;
      NodeId prev = getOrCreateNode(0.0, 0.0, isCorner: true, isSupportPole: true);
      for (int i = 0; i < westRuns.length; i++) {
        acc += westRuns[i].geometricSpan;
        final isEnd = (acc - d).abs() < 0.05 || acc >= d;
        final currentZ = isEnd ? d : acc;
        final isSupport = westSupports[i];
        final curr = getOrCreateNode(0.0, currentZ, isCorner: isEnd, isSupportPole: isSupport || isEnd);
        final edgeId = EdgeId('e_west_' + i.toString());
        edges[edgeId] = MandapEdge(
          id: edgeId,
          startNodeId: prev,
          endNodeId: curr,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        prev = curr;
      }
    }

    // 5. Center Control Node / Center Dot at (w/2, d/2)
    if (params.includeCenterControlPoint) {
      final centerId = NodeId('n_center');
      nodes[centerId] = MandapNode(
        id: centerId,
        x: w / 2.0,
        z: d / 2.0,
        elevation: h,
        height: h,
        type: NodeType.controlPoint,
        support: NodeSupport.none,
        structureId: 'main',
      );

      if (params.preferredPoleSpacing == 10.0 || params.generateModularBayGrid) {
        final midNorth = getOrCreateNode(w / 2.0, 0.0, isCorner: false, isSupportPole: false);
        final midEast = getOrCreateNode(w, d / 2.0, isCorner: false, isSupportPole: false);
        final midSouth = getOrCreateNode(w / 2.0, d, isCorner: false, isSupportPole: false);
        final midWest = getOrCreateNode(0.0, d / 2.0, isCorner: false, isSupportPole: false);

        edges[EdgeId('e_cross_north')] = MandapEdge(
          id: EdgeId('e_cross_north'),
          startNodeId: midNorth,
          endNodeId: centerId,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        edges[EdgeId('e_cross_east')] = MandapEdge(
          id: EdgeId('e_cross_east'),
          startNodeId: centerId,
          endNodeId: midEast,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        edges[EdgeId('e_cross_south')] = MandapEdge(
          id: EdgeId('e_cross_south'),
          startNodeId: centerId,
          endNodeId: midSouth,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
        edges[EdgeId('e_cross_west')] = MandapEdge(
          id: EdgeId('e_cross_west'),
          startNodeId: midWest,
          endNodeId: centerId,
          profile: EdgeProfile.box,
          role: TrussMemberRole.upper,
        );
      }
    }

    return MandapLayout(
      nodes: nodes,
      edges: edges,
      zones: const [],
    );
  }
}