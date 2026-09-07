import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/application/coordinate_transform.dart';

void main() {
  group('CoordinateTransform Exact Placement', () {
    test('round-trip 3D ray intersection matches exact coordinate', () {
      final viewportSize = const Size(1920, 1080);
      
      // Setup a typical camera matrix
      final cameraElevation = 45.0 * 3.14159 / 180.0;
      final cameraAzimuth = 45.0 * 3.14159 / 180.0;
      final cameraDistance = 80.0;
      
      final centerTarget = v64.Vector3(20.0, 5.0, 15.0);
      final eyePosition = centerTarget + v64.Vector3(
        cameraDistance * 0.707 * 0.707,
        cameraDistance * 0.707,
        cameraDistance * 0.707 * 0.707,
      );
      
      final viewMatrix = v64.makeViewMatrix(
        eyePosition,
        centerTarget,
        v64.Vector3(0.0, 1.0, 0.0),
      );
      
      final aspect = viewportSize.width / viewportSize.height;
      final projectionMatrix = v64.makePerspectiveMatrix(
        45.0 * 3.14159 / 180.0,
        aspect,
        1.0,
        1000.0,
      );

      // Define an exact world domain coordinate to test
      final originalPoint = v64.Vector3(5.25, 10.0, 3.75); // X: 5.25, Y(height): 10, Z: 3.75

      // 1. World to Screen
      final screenOffset = CoordinateTransform.worldToScreen3D(
        worldPoint: originalPoint,
        viewportSize: viewportSize,
        viewMatrix: viewMatrix,
        projectionMatrix: projectionMatrix,
      );
      
      expect(screenOffset, isNotNull);

      // 2. Screen to Ray
      final ray = CoordinateTransform.screen3DToWorldRay(
        screenPoint: screenOffset!,
        viewportSize: viewportSize,
        viewMatrix: viewMatrix,
        projectionMatrix: projectionMatrix,
      );

      // 3. Ray to Plane Intersection (testing elevated node plane)
      final intersection = CoordinateTransform.rayHorizontalPlaneIntersection(
        ray,
        10.0,
      );

      expect(intersection, isNotNull);
      
      // Tolerance check (1e-4) due to float/double matrix precision
      expect((intersection!.x - originalPoint.x).abs(), lessThan(1e-4));
      expect((intersection.y - originalPoint.y).abs(), lessThan(1e-4));
      expect((intersection.z - originalPoint.z).abs(), lessThan(1e-4));
    });
  });
}
