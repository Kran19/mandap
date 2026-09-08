import 'package:meta/meta.dart';

/// Formal measurement specification for a Truss structure.
/// Passed from the UI measurement wizard into [TrussGenerator].
/// The generator is responsible for converting this into [MandapLayout] topology.
@immutable
class TrussSpecification {
  /// Width of the truss perimeter (X-axis) in feet.
  final double width;

  /// Depth of the truss perimeter (Z-axis) in feet.
  final double depth;

  /// Height/elevation of the top chord above ground in feet.
  final double elevation;

  /// Optional label (e.g., "Main Stage Truss")
  final String? label;

  const TrussSpecification({
    required this.width,
    required this.depth,
    required this.elevation,
    this.label,
  })  : assert(width > 0, 'Truss width must be positive'),
        assert(depth > 0, 'Truss depth must be positive'),
        assert(elevation >= 0, 'Truss elevation cannot be negative');
}

/// Formal measurement specification for a Pipe (vertical support pole).
@immutable
class PoleSpecification {
  /// Height of the pole in feet.
  final double height;

  /// Diameter/radius of the pole in feet (used for visual rendering).
  final double diameter;

  /// Ground X position in feet.
  final double x;

  /// Ground Z position in feet.
  final double z;

  /// Optional label.
  final String? label;

  const PoleSpecification({
    required this.height,
    required this.x,
    required this.z,
    this.diameter = 0.5,
    this.label,
  })  : assert(height > 0, 'Pole height must be positive'),
        assert(diameter > 0, 'Pole diameter must be positive');
}

/// Formal measurement specification for a Flooring/Carpet area.
@immutable
class FlooringSpecification {
  /// Width of the carpet area (X-axis) in feet.
  final double width;

  /// Depth of the carpet area (Z-axis) in feet.
  final double depth;

  /// Thickness in feet (default ~0.05 ft = ~0.6 inches).
  final double thickness;

  /// Ground X position of the top-left corner in feet.
  final double x;

  /// Ground Z position of the top-left corner in feet.
  final double z;

  /// Y-axis rotation in radians.
  final double rotation;

  /// Optional label.
  final String? label;

  const FlooringSpecification({
    required this.width,
    required this.depth,
    required this.x,
    required this.z,
    this.thickness = 0.05,
    this.rotation = 0.0,
    this.label,
  })  : assert(width > 0, 'Flooring width must be positive'),
        assert(depth > 0, 'Flooring depth must be positive');
}

/// Formal measurement specification for a Stage (raised platform).
@immutable
class StageSpecification {
  /// Width of the stage (X-axis) in feet.
  final double width;

  /// Depth of the stage (Z-axis) in feet.
  final double depth;

  /// Height of the stage platform above ground in feet.
  final double height;

  /// Ground X position of the top-left corner in feet.
  final double x;

  /// Ground Z position of the top-left corner in feet.
  final double z;

  /// Y-axis rotation in radians.
  final double rotation;

  /// Optional label.
  final String? label;

  const StageSpecification({
    required this.width,
    required this.depth,
    required this.height,
    required this.x,
    required this.z,
    this.rotation = 0.0,
    this.label,
  })  : assert(width > 0, 'Stage width must be positive'),
        assert(depth > 0, 'Stage depth must be positive'),
        assert(height > 0, 'Stage height must be positive');
}
