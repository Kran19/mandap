import 'dart:math' as math;
import '../entities/boundary_side.dart';
import '../entities/boundary_truss_run.dart';

/// Pure calculation service to generate structural center cross '+' geometry
/// by snapping to the closest existing boundary poles/nodes to the center,
/// without creating redundant or duplicate poles.
class CenterCrossGeometryResult {
  final Map<String, BoundarySide> updatedFourSides;
  final List<BoundaryTrussRun> centerRuns;
  final String centerNodeId;
  final double centerX;
  final double centerZ;

  const CenterCrossGeometryResult({
    required this.updatedFourSides,
    required this.centerRuns,
    required this.centerNodeId,
    required this.centerX,
    required this.centerZ,
  });
}

class CenterCrossGeometryService {
  const CenterCrossGeometryService();

  /// Creates 4 straight orthogonal branches connecting from (targetCenterX, targetCenterZ)
  /// directly to the midpoints of the 4 perimeter walls.
  static CenterCrossGeometryResult generateCenterCross({
    required Map<String, BoundarySide> fourSides,
    required double plotWidth,
    required double plotDepth,
  }) {
    final targetCenterX = plotWidth / 2.0;
    final targetCenterZ = plotDepth / 2.0;

    final updatedSides = <String, BoundarySide>{};

    // 1. Ensure North side has a node at targetCenterX
    final northRes = _ensureNodeAtDist(fourSides['north'], targetDist: targetCenterX, sideId: 'north');
    updatedSides['north'] = northRes.updatedSide;

    // 2. Ensure South side has a node at targetCenterX
    final southRes = _ensureNodeAtDist(fourSides['south'], targetDist: targetCenterX, sideId: 'south');
    updatedSides['south'] = southRes.updatedSide;

    // 3. Ensure West side has a node at targetCenterZ
    final westRes = _ensureNodeAtDist(fourSides['west'], targetDist: targetCenterZ, sideId: 'west');
    updatedSides['west'] = westRes.updatedSide;

    // 4. Ensure East side has a node at targetCenterZ
    final eastRes = _ensureNodeAtDist(fourSides['east'], targetDist: targetCenterZ, sideId: 'east');
    updatedSides['east'] = eastRes.updatedSide;

    final centerNodeId = 'node_center_${targetCenterX.round()}_${targetCenterZ.round()}';

    final centerRuns = [
      BoundaryTrussRun(
        id: 'center_run_west',
        startNodeId: westRes.nodeId,
        endNodeId: centerNodeId,
        sideId: 'center',
        geometricSpan: targetCenterX,
      ),
      BoundaryTrussRun(
        id: 'center_run_east',
        startNodeId: centerNodeId,
        endNodeId: eastRes.nodeId,
        sideId: 'center',
        geometricSpan: plotWidth - targetCenterX,
      ),
      BoundaryTrussRun(
        id: 'center_run_north',
        startNodeId: northRes.nodeId,
        endNodeId: centerNodeId,
        sideId: 'center',
        geometricSpan: targetCenterZ,
      ),
      BoundaryTrussRun(
        id: 'center_run_south',
        startNodeId: centerNodeId,
        endNodeId: southRes.nodeId,
        sideId: 'center',
        geometricSpan: plotDepth - targetCenterZ,
      ),
    ];

    return CenterCrossGeometryResult(
      updatedFourSides: updatedSides,
      centerRuns: centerRuns,
      centerNodeId: centerNodeId,
      centerX: targetCenterX,
      centerZ: targetCenterZ,
    );
  }

  /// Ensures a node exists on [side] at [targetDist]. If none exists within 0.05, splits the run.
  static ({BoundarySide updatedSide, String nodeId}) _ensureNodeAtDist(
    BoundarySide? side, {
    required double targetDist,
    required String sideId,
  }) {
    if (side == null || side.runs.isEmpty) {
      final fallbackId = '${sideId}_node_mid';
      return (
        updatedSide: BoundarySide(id: sideId, runs: []),
        nodeId: fallbackId,
      );
    }

    double accumulated = 0.0;
    for (int i = 0; i < side.runs.length; i++) {
      final run = side.runs[i];
      final startPos = accumulated;
      final endPos = accumulated + run.geometricSpan;
      accumulated = endPos;

      // Check start node
      if ((startPos - targetDist).abs() < 0.05) {
        return (updatedSide: side, nodeId: run.startNodeId);
      }
      // Check end node
      if ((endPos - targetDist).abs() < 0.05) {
        return (updatedSide: side, nodeId: run.endNodeId);
      }

      // Check if target falls strictly inside this run -> split it cleanly
      if (targetDist > startPos + 0.05 && targetDist < endPos - 0.05) {
        final splitSpan1 = targetDist - startPos;
        final splitSpan2 = endPos - targetDist;
        final midNodeId = '${sideId}_node_mid_${targetDist.round()}';

        final newRuns = <BoundaryTrussRun>[];
        for (int j = 0; j < side.runs.length; j++) {
          if (j == i) {
            newRuns.add(BoundaryTrussRun(
              id: '${run.id}_1',
              startNodeId: run.startNodeId,
              endNodeId: midNodeId,
              sideId: run.sideId,
              geometricSpan: splitSpan1,
            ));
            newRuns.add(BoundaryTrussRun(
              id: '${run.id}_2',
              startNodeId: midNodeId,
              endNodeId: run.endNodeId,
              sideId: run.sideId,
              geometricSpan: splitSpan2,
            ));
          } else {
            newRuns.add(side.runs[j]);
          }
        }
        return (
          updatedSide: BoundarySide(id: side.id, runs: newRuns),
          nodeId: midNodeId,
        );
      }
    }

    // Fallback if not found inside bounds
    final lastNodeId = side.runs.last.endNodeId;
    return (updatedSide: side, nodeId: lastNodeId);
  }

  /// Finds the existing node on [side] that is closest to [targetDist].
  /// If intermediate nodes exist, prioritizes intermediate nodes over corner nodes.
  static ({String nodeId, double pos}) _findClosestNodeOnSide(
    BoundarySide? side, {
    required double targetDist,
    required double totalLength,
  }) {
    if (side == null || side.runs.isEmpty) {
      return (nodeId: 'node_${targetDist.round()}', pos: targetDist);
    }

    // Collect all nodes and their distances along this side
    final nodes = <({String nodeId, double pos, bool isCorner})>[];
    double accumulated = 0.0;
    nodes.add((nodeId: side.runs.first.startNodeId, pos: 0.0, isCorner: true));

    for (int i = 0; i < side.runs.length; i++) {
      final run = side.runs[i];
      accumulated += run.geometricSpan;
      final isLast = i == side.runs.length - 1;
      nodes.add((
        nodeId: run.endNodeId,
        pos: accumulated,
        isCorner: isLast,
      ));
    }

    // Filter intermediate nodes if available
    final intermediateNodes = nodes.where((n) => !n.isCorner).toList();
    final candidatePool = intermediateNodes.isNotEmpty ? intermediateNodes : nodes;

    // Find node with minimum distance to targetDist
    var closest = candidatePool.first;
    var minDiff = (closest.pos - targetDist).abs();

    for (final candidate in candidatePool) {
      final diff = (candidate.pos - targetDist).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = candidate;
      }
    }

    return (nodeId: closest.nodeId, pos: closest.pos);
  }
}

