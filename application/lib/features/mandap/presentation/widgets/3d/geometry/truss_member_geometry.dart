import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/edge_id.dart';
import '../../../../domain/entities/node_id.dart';

/// Single visual standard cross-section width for modular box truss (12 inches / 1.0 ft).
const double boxTrussVisualWidthFeet = 1.0;

/// Represents a single tubular aluminum segment in world-space.
class TrussTubeSegment {
  final v64.Vector3 start;
  final v64.Vector3 end;
  final EdgeId? edgeId;
  final bool isTopChord;

  const TrussTubeSegment({
    required this.start,
    required this.end,
    this.edgeId,
    this.isTopChord = false,
  });
}

/// Represents a realistic metal base plate at a tower's ground contact point.
class TrussBasePlate {
  final NodeId? nodeId;
  final v64.Vector3 center;
  final double halfW;
  final double collarHalfW;
  final List<v64.Vector3> cornerBolts;

  const TrussBasePlate({
    this.nodeId,
    required this.center,
    this.halfW = 1.0,
    this.collarHalfW = 0.65,
    required this.cornerBolts,
  });
}

/// Represents a modular 6-way cube corner/junction connector derived from actual node topology.
class TrussConnectorCube {
  final NodeId nodeId;
  final v64.Vector3 center;
  final double halfExtent;
  final List<v64.Vector3> baseCorners;
  final List<v64.Vector3> topCorners;

  const TrussConnectorCube({
    required this.nodeId,
    required this.center,
    this.halfExtent = 0.52,
    required this.baseCorners,
    required this.topCorners,
  });
}

/// Generated visual 3D geometry for a single box-truss member.
class TrussBoxGeometry {
  final EdgeId edgeId;
  final List<TrussTubeSegment> primaryChords; // 4 primary longitudinal chords
  final List<TrussTubeSegment> latticeStruts; // 4-face Warren diagonal struts
  final List<TrussTubeSegment> transverseTies; // Modular frame ties

  const TrussBoxGeometry({
    required this.edgeId,
    required this.primaryChords,
    required this.latticeStruts,
    required this.transverseTies,
  });
}

/// Generated visual 3D geometry for a vertical tower column.
class TrussTowerGeometry {
  final NodeId? sourceNodeId;
  final EdgeId? sourceEdgeId;
  final double bx;
  final double bz;
  final double fullHeight;
  final List<TrussTubeSegment> verticalChords; // 4 primary vertical chords
  final List<TrussTubeSegment> latticeStruts; // 4-face Warren diagonal struts
  final List<TrussTubeSegment> transverseTies; // Horizontal tower tie rungs
  final TrussBasePlate basePlate;
  final TrussConnectorCube? topConnector;

  const TrussTowerGeometry({
    this.sourceNodeId,
    this.sourceEdgeId,
    required this.bx,
    required this.bz,
    required this.fullHeight,
    required this.verticalChords,
    required this.latticeStruts,
    required this.transverseTies,
    required this.basePlate,
    this.topConnector,
  });
}
