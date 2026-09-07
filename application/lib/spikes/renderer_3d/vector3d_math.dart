import 'package:vector_math/vector_math_64.dart';

/// 3D Geometry Utilities for Perspective Projection, Raycasting, and Ray-Plane Intersections.
class Vector3DMath {
  /// Unprojects a 2D viewport screen coordinate into a 3D world space Ray.
  static Ray screenToRay({
    required Vector2 screenPoint,
    required Vector2 viewportSize,
    required Matrix4 viewMatrix,
    required Matrix4 projectionMatrix,
  }) {
    // Convert screen coordinates to Normalized Device Coordinates (NDC) [-1, 1]
    final ndcX = (2.0 * screenPoint.x) / viewportSize.x - 1.0;
    final ndcY = 1.0 - (2.0 * screenPoint.y) / viewportSize.y;

    final invertedMatrix = Matrix4.copy(projectionMatrix)..multiply(viewMatrix);
    invertedMatrix.invert();

    final nearVec = Vector4(ndcX, ndcY, -1.0, 1.0);
    final farVec = Vector4(ndcX, ndcY, 1.0, 1.0);

    final nearResult = invertedMatrix.transformed(nearVec);
    final farResult = invertedMatrix.transformed(farVec);

    if (nearResult.w != 0.0) nearResult.scale(1.0 / nearResult.w);
    if (farResult.w != 0.0) farResult.scale(1.0 / farResult.w);

    final origin = Vector3(nearResult.x, nearResult.y, nearResult.z);
    final direction = Vector3(
      farResult.x - nearResult.x,
      farResult.y - nearResult.y,
      farResult.z - nearResult.z,
    )..normalize();

    return Ray.originDirection(origin, direction);
  }

  /// Calculates ray-plane intersection point on a horizontal plane at height Y = [planeY].
  static Vector3? rayHorizontalPlaneIntersection(Ray ray, double planeY) {
    if (ray.direction.y.abs() < 1e-6) return null; // Parallel ray

    final t = (planeY - ray.origin.y) / ray.direction.y;
    if (t < 0) return null; // Intersection behind camera

    return ray.origin + (ray.direction * t);
  }

  /// Calculates distance from a point to a 3D finite line segment [p1, p2].
  static double distanceToSegment(Vector3 point, Vector3 p1, Vector3 p2) {
    final v = p2 - p1;
    final w = point - p1;

    final c1 = w.dot(v);
    if (c1 <= 0) return (point - p1).length;

    final c2 = v.dot(v);
    if (c2 <= c1) return (point - p2).length;

    final b = c1 / c2;
    final pb = p1 + (v * b);
    return (point - pb).length;
  }
}
