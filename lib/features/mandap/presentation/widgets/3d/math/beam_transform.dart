import 'package:vector_math/vector_math_64.dart' as v64;

/// Renderer-independent spatial representation of a horizontal or diagonal 3D beam.
class BeamTransform {
  /// Center/midpoint position in 3D world space (X, Y, Z).
  final v64.Vector3 center;

  /// Start endpoint in 3D world space.
  final v64.Vector3 start;

  /// End endpoint in 3D world space.
  final v64.Vector3 end;

  /// Geometric 3D length of the beam.
  final double length;

  /// Normalized direction vector from start to end.
  final v64.Vector3 direction;

  /// Azimuth angle in radians on the horizontal X-Z plane relative to +X axis.
  final double azimuthAngle;

  const BeamTransform({
    required this.center,
    required this.start,
    required this.end,
    required this.length,
    required this.direction,
    required this.azimuthAngle,
  });
}
