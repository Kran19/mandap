import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../../../core/geometry/length.dart';
import '../../../../domain/entities/mandap_node.dart';

/// Result of a 3D constrained edge handle drag operation.
class EdgeDragResult {
  final Length snappedLength;
  final double newX;
  final double newZ;
  final bool hasValueChanged;

  const EdgeDragResult({
    required this.snappedLength,
    required this.newX,
    required this.newZ,
    required this.hasValueChanged,
  });
}

/// Result of a 3D node drag operation.
class NodeDragResult {
  final double newX;
  final double newZ;
  final bool hasValueChanged;

  const NodeDragResult({
    required this.newX,
    required this.newZ,
    required this.hasValueChanged,
  });
}

/// Pure mathematical calculator for camera-independent 3D constrained drag interactions.
class DragConstraintCalculator {
  /// Minimum allowed beam length in feet.
  static const double minBeamLengthFeet = 1.0;

  /// Snaps a scalar value to the nearest increment of [gridSpacing].
  static double snapToGrid(double value, double gridSpacing) {
    return (value / gridSpacing).round() * gridSpacing;
  }

  /// Convenience method: snaps a scalar value in feet to the nearest 0.5-foot increment.
  static double snapToHalfFoot(double value) => snapToGrid(value, 0.5);

  /// Calculates camera-independent edge handle drag along the original edge axis vector.
  static EdgeDragResult calculateEdgeHandleDrag({
    required MandapNode startNode,
    required MandapNode endNode,
    required v64.Vector3 planeIntersectionPoint,
    required double currentLengthFeet,
    double gridSpacing = 0.5,
  }) {
    final startPos = v64.Vector3(startNode.x, 0.0, startNode.z);
    final endPos = v64.Vector3(endNode.x, 0.0, endNode.z);
    final hitPos = v64.Vector3(
      planeIntersectionPoint.x,
      0.0,
      planeIntersectionPoint.z,
    );

    var axisDir = endPos - startPos;
    final axisLength = axisDir.length;
    if (axisLength < 1e-4) {
      axisDir = v64.Vector3(1.0, 0.0, 0.0);
    } else {
      axisDir.normalize();
    }

    // Project intersection onto edge axis direction ray
    final projDist = (hitPos - startPos).dot(axisDir);
    final rawFeet = math.max(minBeamLengthFeet, projDist);

    // Snap distance to nearest grid
    final snappedFeet = snapToGrid(rawFeet, gridSpacing);
    final snappedLength = Length.fromFeet(snappedFeet);

    final newX = startNode.x + axisDir.x * snappedFeet;
    final newZ = startNode.z + axisDir.z * snappedFeet;

    final hasValueChanged = (snappedFeet - currentLengthFeet).abs() >= 0.01;

    return EdgeDragResult(
      snappedLength: snappedLength,
      newX: newX,
      newZ: newZ,
      hasValueChanged: hasValueChanged,
    );
  }

  /// Calculates camera-independent 3D node drag on the X-Z ground plane.
  static NodeDragResult calculateNodeDrag({
    required MandapNode currentNode,
    required v64.Vector3 planeIntersectionPoint,
    double gridSpacing = 0.5,
  }) {
    final rawX = planeIntersectionPoint.x;
    final rawZ = planeIntersectionPoint.z;

    final snappedX = snapToGrid(rawX, gridSpacing);
    final snappedZ = snapToGrid(rawZ, gridSpacing);

    final hasValueChanged =
        (snappedX - currentNode.x).abs() >= 0.01 ||
        (snappedZ - currentNode.z).abs() >= 0.01;

    return NodeDragResult(
      newX: snappedX,
      newZ: snappedZ,
      hasValueChanged: hasValueChanged,
    );
  }
}
