import 'package:meta/meta.dart';

/// Configuration style for the roof canopy topology.
enum TrussConfiguration {
  fivePoint,
  sixPoint,
}

/// Formal measurement specification for a Truss structure.
/// Passed from the UI measurement wizard into [TrussGenerator].
/// The generator is responsible for converting this into [MandapLayout] topology.
@immutable
class TrussSpecification {
  /// Total width of the truss perimeter (X-axis) in feet.
  final double width;

  /// Total depth of the truss perimeter (Z-axis) in feet.
  final double depth;

  /// Overall height of the vertical tower in feet.
  final double height;

  /// Width of the central tower cross-section in feet.
  final double towerWidth;

  /// Depth of the central tower cross-section in feet.
  final double towerDepth;

  /// Elevation of the main horizontal truss / canopy roof in feet.
  final double roofElevation;

  /// Structural separation between top and bottom chords in feet.
  final double profileHeight;

  /// Inventory segment block length in feet (e.g., 10ft spans).
  final double memberSegmentLength;

  /// The topological layout style of the roof (5-point vs 6-point).
  final TrussConfiguration configuration;

  /// Optional label (e.g., "Main Stage Truss")
  final String? label;

  const TrussSpecification({
    required this.width,
    required this.depth,
    required this.height,
    this.towerWidth = 2.0,
    this.towerDepth = 2.0,
    required this.roofElevation,
    this.profileHeight = 1.0,
    this.memberSegmentLength = 10.0,
    this.configuration = TrussConfiguration.fivePoint,
    this.label,
  })  : assert(width > 0, 'Truss width must be positive'),
        assert(depth > 0, 'Truss depth must be positive'),
        assert(height > 0, 'Tower height must be positive'),
        assert(towerWidth > 0, 'Tower width must be positive'),
        assert(towerDepth > 0, 'Tower depth must be positive'),
        assert(roofElevation >= 0 && roofElevation <= height, 'Roof elevation must be between 0 and tower height'),
        assert(profileHeight > 0, 'Profile height must be positive'),
        assert(memberSegmentLength > 0, 'Member segment length must be positive');
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
