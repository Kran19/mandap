import '../entities/boundary_pole.dart';
import '../entities/boundary_side.dart';
import '../entities/boundary_truss_run.dart';
import '../entities/truss_size.dart';
import 'truss_pole_requirement_service.dart';

/// Pure calculation engine for placing boundary poles along the perimeter.
///
/// Distinguishes between:
/// - Corner physical support poles (isCorner = true, isSupportPole = true)
/// - Intermediate physical support poles (isSupportPole = true, per truss interval rule)
/// - Intermediate structural joints / connection points (isSupportPole = false)
class BoundaryPoleGenerator {
  static const double epsilon = 0.05;

  const BoundaryPoleGenerator();

  /// Generates unique structural boundary nodes/poles from the 4 boundary sides 
  /// given a dynamic [width] and [depth].
  static List<BoundaryPole> generatePoles(
    Map<String, BoundarySide> fourSides, {
    required double width,
    required double depth,
    TrussSize? trussSize,
  }) {
    // Collect raw poles per side with their exact plot coordinates
    final rawPoles = <({double x, double z, String sideId, bool isCorner, bool isSupportPole})>[];

    // 1. North side (Top): from (0, 0) to (width, 0) along +X
    if (fourSides.containsKey('north')) {
      _collectSidePoles(
        side: fourSides['north']!,
        sideId: 'north',
        sideDimension: width,
        originX: 0.0,
        originZ: 0.0,
        stepX: 1.0,
        stepZ: 0.0,
        plotWidth: width,
        plotDepth: depth,
        trussSize: trussSize,
        targetList: rawPoles,
      );
    }

    // 2. East side (Right): from (width, 0) to (width, depth) along +Z
    if (fourSides.containsKey('east')) {
      _collectSidePoles(
        side: fourSides['east']!,
        sideId: 'east',
        sideDimension: depth,
        originX: width,
        originZ: 0.0,
        stepX: 0.0,
        stepZ: 1.0,
        plotWidth: width,
        plotDepth: depth,
        trussSize: trussSize,
        targetList: rawPoles,
      );
    }

    // 3. South side (Bottom): from (0, depth) to (width, depth) along +X (aligned with North)
    if (fourSides.containsKey('south')) {
      _collectSidePoles(
        side: fourSides['south']!,
        sideId: 'south',
        sideDimension: width,
        originX: 0.0,
        originZ: depth,
        stepX: 1.0,
        stepZ: 0.0,
        plotWidth: width,
        plotDepth: depth,
        trussSize: trussSize,
        targetList: rawPoles,
      );
    }

    // 4. West side (Left): from (0, 0) to (0, depth) along +Z (aligned with East)
    if (fourSides.containsKey('west')) {
      _collectSidePoles(
        side: fourSides['west']!,
        sideId: 'west',
        sideDimension: depth,
        originX: 0.0,
        originZ: 0.0,
        stepX: 0.0,
        stepZ: 1.0,
        plotWidth: width,
        plotDepth: depth,
        trussSize: trussSize,
        targetList: rawPoles,
      );
    }

    // Deduplicate shared nodes (especially corner poles)
    final uniquePoles = <String, BoundaryPole>{};

    for (final raw in rawPoles) {
      final key = '${raw.x.toStringAsFixed(2)}_${raw.z.toStringAsFixed(2)}';
      if (uniquePoles.containsKey(key)) {
        final existing = uniquePoles[key]!;
        final updatedSides = {...existing.connectedSideIds, raw.sideId}.toList();
        final isCorner = existing.isCorner || raw.isCorner;
        final isSupportPole = existing.isSupportPole || raw.isSupportPole || isCorner;

        uniquePoles[key] = BoundaryPole(
          id: existing.id,
          x: existing.x,
          z: existing.z,
          isCorner: isCorner,
          isSupportPole: isSupportPole,
          connectedSideIds: updatedSides,
        );
      } else {
        uniquePoles[key] = BoundaryPole(
          id: 'pole_${raw.x.round()}_${raw.z.round()}',
          x: raw.x,
          z: raw.z,
          isCorner: raw.isCorner,
          isSupportPole: raw.isSupportPole || raw.isCorner,
          connectedSideIds: [raw.sideId],
        );
      }
    }

    return List.unmodifiable(uniquePoles.values.toList());
  }

  /// Calculates positions along one side from 0 to sideDimension based on run accumulation.
  static List<double> calculateSideJointPositions(BoundarySide side, double sideDimension) {
    final positions = <double>[0.0];
    double accumulated = 0.0;

    for (final run in side.runs) {
      accumulated += run.geometricSpan;
      if (accumulated <= sideDimension + epsilon) {
        positions.add(accumulated > sideDimension ? sideDimension : accumulated);
      }
    }

    if ((positions.last - sideDimension).abs() > epsilon) {
      positions.add(sideDimension);
    } else {
      positions[positions.length - 1] = sideDimension;
    }

    return positions;
  }

  /// Calculates support flag for each run end point. All primary structural run endpoints
  /// generated in the perimeter breakdown (e.g. 60ft, 30ft, 10ft) are physical support poles,
  /// while midpoint connection split nodes do not add extra support poles.
  static List<bool> calculateRunSupports(List<BoundaryTrussRun> runs, TrussSize? trussSize) {
    if (runs.isEmpty) return [];
    return runs.map((r) {
      if (r.endNodeId.contains('_node_mid_')) {
        return false;
      }
      return true;
    }).toList();
  }

  static void _collectSidePoles({
    required BoundarySide side,
    required String sideId,
    required double sideDimension,
    required double originX,
    required double originZ,
    required double stepX,
    required double stepZ,
    required double plotWidth,
    required double plotDepth,
    required TrussSize? trussSize,
    required List<({double x, double z, String sideId, bool isCorner, bool isSupportPole})> targetList,
  }) {
    final positions = calculateSideJointPositions(side, sideDimension);
    final runSupports = calculateRunSupports(side.runs, trussSize);

    for (int i = 0; i < positions.length; i++) {
      final dist = positions[i];
      final x = (originX + dist * stepX).clamp(0.0, plotWidth);
      final z = (originZ + dist * stepZ).clamp(0.0, plotDepth);
      final isCorner = _isPlotCorner(x, z, plotWidth, plotDepth);
      final isSupport = isCorner || (i > 0 && i - 1 < runSupports.length && runSupports[i - 1]);

      targetList.add((
        x: (x * 100).roundToDouble() / 100,
        z: (z * 100).roundToDouble() / 100,
        sideId: sideId,
        isCorner: isCorner,
        isSupportPole: isSupport,
      ));
    }
  }

  static bool _isPlotCorner(double x, double z, double w, double d) {
    final isXCorner = (x - 0.0).abs() < epsilon || (x - w).abs() < epsilon;
    final isZCorner = (z - 0.0).abs() < epsilon || (z - d).abs() < epsilon;
    return isXCorner && isZCorner;
  }
}
