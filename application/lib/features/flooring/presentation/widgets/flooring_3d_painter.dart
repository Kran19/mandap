import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/flooring_calculation_result.dart';
import '../../domain/models/flooring_carpet.dart';

class Flooring3DPainter extends CustomPainter {
  final FlooringCalculationResult result;
  final double cameraAzimuth;
  final double cameraElevation;
  final double cameraZoom;

  Flooring3DPainter({
    required this.result,
    this.cameraAzimuth = math.pi / 4,
    this.cameraElevation = math.pi / 5,
    this.cameraZoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || result.plotLength <= 0 || result.plotWidth <= 0) return;

    // Dark Engineering Viewport Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F172A),
    );

    final centerTarget = v64.Vector3(
      result.coveredLength / 2,
      0.1,
      result.coveredWidth / 2,
    );

    final maxDim = math.max(result.coveredLength, result.coveredWidth);
    final distance = math.max(maxDim * 2.2, 40.0) * cameraZoom;

    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      distance * cosElev * sinAzim,
      distance * sinElev,
      distance * cosElev * cosAzim,
    );

    final eyePosition = centerTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      centerTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = size.width / size.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      2000.0,
    );

    Offset? project(v64.Vector3 worldPoint) {
      final p = projectionMatrix * viewMatrix * v64.Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
      if (p.w == 0) return null;
      final ndc = v64.Vector3(p.x / p.w, p.y / p.w, p.z / p.w);
      if (ndc.z < -1 || ndc.z > 1) return null;

      return Offset(
        (ndc.x + 1.0) * 0.5 * size.width,
        (1.0 - ndc.y) * 0.5 * size.height,
      );
    }

    // Ground Plane Grid (Subtle dark grid beneath carpet)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final groundBoundaryPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gP1 = project(v64.Vector3(-10, 0, -10));
    final gP2 = project(v64.Vector3(result.coveredLength + 10, 0, -10));
    final gP3 = project(v64.Vector3(result.coveredLength + 10, 0, result.coveredWidth + 10));
    final gP4 = project(v64.Vector3(-10, 0, result.coveredWidth + 10));

    if (gP1 != null && gP2 != null && gP3 != null && gP4 != null) {
      final groundPath = Path()
        ..moveTo(gP1.dx, gP1.dy)
        ..lineTo(gP2.dx, gP2.dy)
        ..lineTo(gP3.dx, gP3.dy)
        ..lineTo(gP4.dx, gP4.dy)
        ..close();
      canvas.drawPath(groundPath, groundBoundaryPaint);
    }

    // Sort carpet pieces back-to-front by distance to camera
    final cameraZDir = v64.Vector3(eyeOffset.x, eyeOffset.y, eyeOffset.z)..normalize();
    final sortedCarpets = List<FlooringCarpet>.from(result.carpetLayout)
      ..sort((a, b) {
        final centerA = v64.Vector3(a.x + a.width / 2, 0.1, a.z + a.depth / 2);
        final centerB = v64.Vector3(b.x + b.width / 2, 0.1, b.z + b.depth / 2);
        final vecA = centerA - eyePosition;
        final vecB = centerB - eyePosition;
        return vecB.dot(cameraZDir).compareTo(vecA.dot(cameraZDir));
      });

    final carpetFillPaint = Paint()
      ..color = const Color(0xFFB91C1C) // Event red carpet surface
      ..style = PaintingStyle.fill;

    final carpetSeamPaint = Paint()
      ..color = const Color(0xFFEF4444) // Bright red seam line between carpet pieces
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final carpetFramePaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const carpetY = 0.1; // Minimal carpet height above ground plane

    // Draw individual carpet pieces
    for (final carpet in sortedCarpets) {
      final c0 = project(v64.Vector3(carpet.x, carpetY, carpet.z));
      final c1 = project(v64.Vector3(carpet.x + carpet.width, carpetY, carpet.z));
      final c2 = project(v64.Vector3(carpet.x + carpet.width, carpetY, carpet.z + carpet.depth));
      final c3 = project(v64.Vector3(carpet.x, carpetY, carpet.z + carpet.depth));

      if (c0 != null && c1 != null && c2 != null && c3 != null) {
        final carpetPath = Path()
          ..moveTo(c0.dx, c0.dy)
          ..lineTo(c1.dx, c1.dy)
          ..lineTo(c2.dx, c2.dy)
          ..lineTo(c3.dx, c3.dy)
          ..close();

        canvas.drawPath(carpetPath, carpetFillPaint);
        canvas.drawPath(carpetPath, carpetSeamPaint);
        canvas.drawPath(carpetPath, carpetFramePaint);
      }
    }

    // Draw Requested Plot Boundary (Cyan stroke line on top of carpet surface)
    final p0 = project(v64.Vector3(0, 0.15, 0));
    final p1 = project(v64.Vector3(result.plotLength, 0.15, 0));
    final p2 = project(v64.Vector3(result.plotLength, 0.15, result.plotWidth));
    final p3 = project(v64.Vector3(0, 0.15, result.plotWidth));

    if (p0 != null && p1 != null && p2 != null && p3 != null) {
      final plotPath = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      final plotOutlinePaint = Paint()
        ..color = const Color(0xFF38BDF8) // Cyan plot boundary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawPath(plotPath, plotOutlinePaint);
    }

    // Draw Actual Coverage Boundary (Amber stroke if coverage exceeds plot)
    if (result.coveredLength > result.plotLength || result.coveredWidth > result.plotWidth) {
      final k0 = project(v64.Vector3(0, 0.15, 0));
      final k1 = project(v64.Vector3(result.coveredLength, 0.15, 0));
      final k2 = project(v64.Vector3(result.coveredLength, 0.15, result.coveredWidth));
      final k3 = project(v64.Vector3(0, 0.15, result.coveredWidth));

      if (k0 != null && k1 != null && k2 != null && k3 != null) {
        final covPath = Path()
          ..moveTo(k0.dx, k0.dy)
          ..lineTo(k1.dx, k1.dy)
          ..lineTo(k2.dx, k2.dy)
          ..lineTo(k3.dx, k3.dy)
          ..close();

        final covOutlinePaint = Paint()
          ..color = const Color(0xFFF59E0B) // Amber excess coverage boundary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawPath(covPath, covOutlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Flooring3DPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.cameraAzimuth != cameraAzimuth ||
        oldDelegate.cameraElevation != cameraElevation ||
        oldDelegate.cameraZoom != cameraZoom;
  }
}
