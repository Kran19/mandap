import '../entities/boundary_pole.dart';
import '../entities/center_light_point.dart';

/// Pure generator for single center point and interactive '+' cross structure with poles.
///
/// Invariants:
/// - Only 1 center point at the geometric center of the plot ((plotWidth/2, plotDepth/2)).
/// - When activated, generates a '+' sign cross connecting the 4 boundary sides.
/// - Both lines of the '+' sign come with physical structural poles.
class CenterLightGenerator {
  const CenterLightGenerator();

  /// Generates the single center point at the plot center.
  static List<CenterLightPoint> generateInteriorGrid({
    double plotWidth = 100.0,
    double plotDepth = 100.0,
  }) {
    return List.unmodifiable([
      CenterLightPoint(
        id: 'center_point_main',
        x: (plotWidth / 2.0 * 100).roundToDouble() / 100,
        z: (plotDepth / 2.0 * 100).roundToDouble() / 100,
        state: CenterLightState.inactive,
      ),
    ]);
  }

  /// Generates physical structural poles for both lines of the '+' sign cross.
  static List<BoundaryPole> generateCenterCrossPoles({
    double plotWidth = 100.0,
    double plotDepth = 100.0,
  }) {
    final midX = (plotWidth / 2.0 * 100).roundToDouble() / 100;
    final midZ = (plotDepth / 2.0 * 100).roundToDouble() / 100;

    final poles = <BoundaryPole>[
      // Center pole at intersection
      BoundaryPole(id: 'pole_center_mid', x: midX, z: midZ),

      // Horizontal line poles (at z = midZ)
      BoundaryPole(id: 'pole_cross_h_0', x: 0.0, z: midZ),
      BoundaryPole(id: 'pole_cross_h_25', x: midX / 2.0, z: midZ),
      BoundaryPole(id: 'pole_cross_h_75', x: midX + midX / 2.0, z: midZ),
      BoundaryPole(id: 'pole_cross_h_100', x: plotWidth, z: midZ),

      // Vertical line poles (at x = midX)
      BoundaryPole(id: 'pole_cross_v_0', x: midX, z: 0.0),
      BoundaryPole(id: 'pole_cross_v_25', x: midX, z: midZ / 2.0),
      BoundaryPole(id: 'pole_cross_v_75', x: midX, z: midZ + midZ / 2.0),
      BoundaryPole(id: 'pole_cross_v_100', x: midX, z: plotDepth),
    ];

    // Deduplicate any overlapping coordinates
    final unique = <String, BoundaryPole>{};
    for (final p in poles) {
      final key = '${p.x.toStringAsFixed(2)}_${p.z.toStringAsFixed(2)}';
      unique[key] = p;
    }

    return List.unmodifiable(unique.values.toList());
  }
}
