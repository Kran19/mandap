import 'edge_id.dart';
import 'node_id.dart';

/// Pure-Dart domain representation of an empty rectangular truss module/bay.
///
/// Notice: Does NOT import `dart:ui` or use Flutter `Offset`. Coordinates are
/// pure Dart doubles in the world coordinate space:
/// - X: Horizontal axis (Width)
/// - Z: Depth axis (Length)
class TrussBay {
  /// Transient UI identity (e.g. `bay_c0_r0`), derived from grid ordering.
  final String id;

  /// Grid column index (0-indexed).
  final int columnIndex;

  /// Grid row index (0-indexed).
  final int rowIndex;

  /// World bounding limits of this bay.
  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;

  /// Pure Dart 2D center point coordinates (X and Z).
  final double centerX;
  final double centerZ;

  /// The 4 authoritative corner node IDs forming this bay:
  /// [topLeft (minX, minZ), topRight (maxX, minZ),
  ///  bottomRight (maxX, maxZ), bottomLeft (minX, maxZ)].
  final List<NodeId> cornerNodeIds;

  /// The 4 authoritative boundary edge IDs enclosing this bay:
  /// [top, right, bottom, left].
  final List<EdgeId> boundaryEdgeIds;

  /// Whether an internal member cuts through this bay.
  final bool hasInternalMembers;

  const TrussBay({
    required this.id,
    required this.columnIndex,
    required this.rowIndex,
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
    required this.centerX,
    required this.centerZ,
    required this.cornerNodeIds,
    required this.boundaryEdgeIds,
    this.hasInternalMembers = false,
  });

  /// Width of this bay along the X axis in feet.
  double get widthFt => maxX - minX;

  /// Length of this bay along the Z axis in feet.
  double get lengthFt => maxZ - minZ;

  /// Aliases for feet getters
  double get widthFeet => widthFt;
  double get lengthFeet => lengthFt;

  /// Returns true if the given world (x, z) point is inside this bay.
  bool containsPoint(double x, double z, [double tolerance = 0.0]) {
    return x >= (minX - tolerance) &&
        x <= (maxX + tolerance) &&
        z >= (minZ - tolerance) &&
        z <= (maxZ + tolerance);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrussBay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          minX == other.minX &&
          maxX == other.maxX &&
          minZ == other.minZ &&
          maxZ == other.maxZ;

  @override
  int get hashCode => Object.hash(id, minX, maxX, minZ, maxZ);

  @override
  String toString() =>
      'TrussBay($id: ${widthFt.toStringAsFixed(1)}ft x ${lengthFt.toStringAsFixed(1)}ft at [$minX..$maxX, $minZ..$maxZ])';
}
