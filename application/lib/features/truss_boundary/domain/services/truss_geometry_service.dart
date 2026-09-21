import '../entities/boundary_side.dart';
import '../entities/boundary_truss_run.dart';

/// Geometry editor that mutates the graph (Splits and Merges).
/// It operates purely on the structural geometry without material consideration.
class TrussGeometryService {
  const TrussGeometryService();

  /// Splits an existing [runToSplit] inside [side] into two pieces at [splitOffset] (relative to the run start).
  static BoundarySide splitRun({
    required BoundarySide side,
    required String runId,
    required double splitOffset,
    required String newPoleId,
  }) {
    final runIndex = side.runs.indexWhere((r) => r.id == runId);
    if (runIndex == -1) throw ArgumentError('Run not found.');
    
    final originalRun = side.runs[runIndex];
    
    if (splitOffset <= 0 || splitOffset >= originalRun.geometricSpan) {
      throw ArgumentError('Invalid split offset.');
    }

    // Create the two new runs
    final firstRun = BoundaryTrussRun(
      id: '${originalRun.id}_part1',
      startNodeId: originalRun.startNodeId,
      endNodeId: newPoleId,
      sideId: originalRun.sideId,
      geometricSpan: splitOffset,
    );
    
    final secondRun = BoundaryTrussRun(
      id: '${originalRun.id}_part2',
      startNodeId: newPoleId,
      endNodeId: originalRun.endNodeId,
      sideId: originalRun.sideId,
      geometricSpan: originalRun.geometricSpan - splitOffset,
    );

    final newRuns = <BoundaryTrussRun>[];
    for (int i = 0; i < side.runs.length; i++) {
      if (i == runIndex) {
        newRuns.add(firstRun);
        newRuns.add(secondRun);
      } else {
        newRuns.add(side.runs[i]);
      }
    }

    return BoundarySide(id: side.id, runs: newRuns);
  }

  /// Merges two adjacent runs inside [side] by removing their shared intermediate pole.
  static BoundarySide mergeRuns({
    required BoundarySide side,
    required String runIdA,
    required String runIdB,
  }) {
    final indexA = side.runs.indexWhere((r) => r.id == runIdA);
    final indexB = side.runs.indexWhere((r) => r.id == runIdB);

    if (indexA == -1 || indexB == -1) throw ArgumentError('Runs not found.');
    if ((indexA - indexB).abs() != 1) throw ArgumentError('Runs must be adjacent.');

    final firstIndex = indexA < indexB ? indexA : indexB;
    final secondIndex = indexA < indexB ? indexB : indexA;

    final firstRun = side.runs[firstIndex];
    final secondRun = side.runs[secondIndex];

    if (firstRun.endNodeId != secondRun.startNodeId) {
      throw StateError('Graph integrity error: Adjacent runs do not share a pole.');
    }

    final mergedRun = BoundaryTrussRun(
      id: '${firstRun.id}_merged_${DateTime.now().microsecondsSinceEpoch}',
      startNodeId: firstRun.startNodeId,
      endNodeId: secondRun.endNodeId,
      sideId: firstRun.sideId,
      geometricSpan: firstRun.geometricSpan + secondRun.geometricSpan,
    );

    final newRuns = <BoundaryTrussRun>[];
    for (int i = 0; i < side.runs.length; i++) {
      if (i == firstIndex) {
        newRuns.add(mergedRun);
      } else if (i == secondIndex) {
        // Skip
        continue;
      } else {
        newRuns.add(side.runs[i]);
      }
    }

    return BoundarySide(id: side.id, runs: newRuns);
  }
}
