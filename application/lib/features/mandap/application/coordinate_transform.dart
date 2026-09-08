import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

/// Centralized service for 2D and 3D coordinate transformations.
/// Ensures mathematical consistency between the 2D engineering grid
/// and the 3D world representation.
class CoordinateTransform {
  // ── 2D Transforms ─────────────────────────────────────────────────────────

  /// Converts a world coordinate (X, Z) into a 2D canvas screen point.
  static Offset worldToCanvas({
    required double worldX,
    required double worldZ,
    required double scale,
    required double panX,
    required double panY,
  }) {
    return Offset(worldX * scale + panX, worldZ * scale + panY);
  }

  /// Converts a 2D canvas screen point into a world coordinate (X, Z).
  static ({double x, double z}) canvasToWorld({
    required Offset screenPoint,
    required double scale,
    required double panX,
    required double panY,
  }) {
    return (
      x: (screenPoint.dx - panX) / scale,
      z: (screenPoint.dy - panY) / scale,
    );
  }

  // ── 3D Transforms ─────────────────────────────────────────────────────────

  /// Projects a 3D world point into a 2D screen coordinate based on camera state.
  static Offset? worldToScreen3D({
    required v64.Vector3 worldPoint,
    required Size viewportSize,
    required v64.Matrix4 viewMatrix,
    required v64.Matrix4 projectionMatrix,
  }) {
    final viewProj = projectionMatrix * viewMatrix;
    final world4 = v64.Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    final clip = viewProj * world4;

    if (clip.w <= 0.0) return null;

    final ndc = v64.Vector3(clip.x / clip.w, clip.y / clip.w, clip.z / clip.w);
    final screenX = (ndc.x + 1.0) * 0.5 * viewportSize.width;
    final screenY = (1.0 - ndc.y) * 0.5 * viewportSize.height;

    return Offset(screenX, screenY);
  }

  /// Casts a ray from a 2D screen coordinate into the 3D world.
  static v64.Ray screen3DToWorldRay({
    required Offset screenPoint,
    required Size viewportSize,
    required v64.Matrix4 viewMatrix,
    required v64.Matrix4 projectionMatrix,
  }) {
    final ndcX = (2.0 * screenPoint.dx) / viewportSize.width - 1.0;
    final ndcY = 1.0 - (2.0 * screenPoint.dy) / viewportSize.height;

    final invertedMatrix = v64.Matrix4.copy(projectionMatrix)..multiply(viewMatrix);
    invertedMatrix.invert();

    final nearVec = v64.Vector4(ndcX, ndcY, -1.0, 1.0);
    final farVec = v64.Vector4(ndcX, ndcY, 1.0, 1.0);

    final nearResult = invertedMatrix.transformed(nearVec);
    final farResult = invertedMatrix.transformed(farVec);

    if (nearResult.w != 0.0) nearResult.scale(1.0 / nearResult.w);
    if (farResult.w != 0.0) farResult.scale(1.0 / farResult.w);

    final origin = v64.Vector3(nearResult.x, nearResult.y, nearResult.z);
    final direction = v64.Vector3(
      farResult.x - nearResult.x,
      farResult.y - nearResult.y,
      farResult.z - nearResult.z,
    )..normalize();

    return v64.Ray.originDirection(origin, direction);
  }

  /// Finds the intersection of a ray with a horizontal plane at [planeY].
  static v64.Vector3? rayHorizontalPlaneIntersection(v64.Ray ray, double planeY) {
    if (ray.direction.y.abs() < 1e-6) return null; // Parallel ray

    final t = (planeY - ray.origin.y) / ray.direction.y;
    if (t < 0) return null; // Intersection behind camera

    return ray.origin + (ray.direction * t);
  }

  // ── Grid & Formatting ─────────────────────────────────────────────────────

  /// Snaps a value to the nearest increment of [gridSpacing].
  static double snapToGrid(double value, double gridSpacing) {
    if (gridSpacing <= 0) return value;
    return (value / gridSpacing).round() * gridSpacing;
  }

  /// Rounds a coordinate value to 2 decimal places for UI display to avoid floating point artifacts.
  static double roundForDisplay(double value) {
    return (value * 100).round() / 100;
  }
}
