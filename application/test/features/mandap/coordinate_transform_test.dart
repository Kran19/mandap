import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

import 'package:mandap/features/mandap/application/coordinate_transform.dart';

void main() {
  group('CoordinateTransform 2D/3D Parity Verification', () {
    test('3D projection and raycast are inverse consistent on known plane', () {
      const viewportSize = Size(1000, 800);
      
      // Setup a perspective camera
      final cameraCenterTarget = v64.Vector3(10, 0, 10);
      final cameraDistance = 30.0;
      final cameraElevation = math.pi / 6; // 30 degrees
      final cameraAzimuth = math.pi / 4;   // 45 degrees

      final cosElev = math.cos(cameraElevation);
      final sinElev = math.sin(cameraElevation);
      final cosAzim = math.cos(cameraAzimuth);
      final sinAzim = math.sin(cameraAzimuth);

      final eyeOffset = v64.Vector3(
        cameraDistance * cosElev * sinAzim,
        cameraDistance * sinElev,
        cameraDistance * cosElev * cosAzim,
      );
      final eyePosition = cameraCenterTarget + eyeOffset;

      final viewMatrix = v64.makeViewMatrix(
        eyePosition,
        cameraCenterTarget,
        v64.Vector3(0.0, 1.0, 0.0),
      );

      final projectionMatrix = v64.makePerspectiveMatrix(
        45.0 * math.pi / 180.0,
        viewportSize.width / viewportSize.height,
        1.0,
        1000.0,
      );

      final testCoordinates = [
        (0.10, 0.10),
        (0.10, 0.90),
        (0.20, 0.20),
        (0.50, 0.50),
        (0.90, 0.90),
        (1.25, 2.75),
        (5.10, 3.20),
      ];

      for (final tc in testCoordinates) {
        final expectedX = tc.$1;
        final expectedZ = tc.$2;
        final groundPlaneY = 0.0;

        // 1. World -> 3D Vector
        final worldPoint = v64.Vector3(expectedX, groundPlaneY, expectedZ);

        // 2. Project -> Screen Coordinate
        final screenPos = CoordinateTransform.worldToScreen3D(
          worldPoint: worldPoint,
          viewportSize: viewportSize,
          viewMatrix: viewMatrix,
          projectionMatrix: projectionMatrix,
        );

        expect(screenPos, isNotNull, reason: 'Point should be within camera view');

        // 3. Screen -> Ray
        final ray = CoordinateTransform.screen3DToWorldRay(
          screenPoint: screenPos!,
          viewportSize: viewportSize,
          viewMatrix: viewMatrix,
          projectionMatrix: projectionMatrix,
        );

        // 4. Ray -> Known Plane Intersection
        final intersection = CoordinateTransform.rayHorizontalPlaneIntersection(ray, groundPlaneY);

        expect(intersection, isNotNull, reason: 'Ray must intersect ground plane');

        // 5. Intersection -> World
        final actualX = intersection!.x;
        final actualZ = intersection.z;

        // Verify within defined numerical tolerance
        expect(
          (actualX - expectedX).abs(),
          lessThan(1e-6),
          reason: 'X coordinate precision lost in round-trip projection',
        );
        expect(
          (actualZ - expectedZ).abs(),
          lessThan(1e-6),
          reason: 'Z coordinate precision lost in round-trip projection',
        );
      }
    });
  });
}
