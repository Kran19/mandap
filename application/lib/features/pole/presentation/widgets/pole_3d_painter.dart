import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/pole_calculation_result.dart';
import '../../domain/models/pole_layout_point.dart';

class Pole3DPainter extends CustomPainter {
  final PoleCalculationResult result;
  final double cameraAzimuth;
  final double cameraElevation;
  final double cameraZoom;
  
  Pole3DPainter({
    required this.result,
    this.cameraAzimuth = math.pi / 4,
    this.cameraElevation = math.pi / 6,
    this.cameraZoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || result.plotLength <= 0 || result.plotWidth <= 0) return;

    // Dark Blueprint Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F19),
    );

    final centerTarget = v64.Vector3(result.plotWidth / 2, 0, result.plotLength / 2);
    
    // Fit camera
    final maxDim = math.max(result.plotWidth, result.plotLength);
    final distance = math.max(maxDim * 2.5, 60.0) * cameraZoom;

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
      1500.0,
    );

    Offset? project(v64.Vector3 worldPoint) {
       final p = projectionMatrix * viewMatrix * v64.Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
       if (p.w == 0) return null;
       final ndc = v64.Vector3(p.x / p.w, p.y / p.w, p.z / p.w);
       if (ndc.z < -1 || ndc.z > 1) return null; // Behind camera
       
       return Offset(
         (ndc.x + 1.0) * 0.5 * size.width,
         (1.0 - ndc.y) * 0.5 * size.height, // Y points up in 3D, down in 2D
       );
    }

    // Draw Plot Boundary and Ground Grid
    final boundaryPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Build clamped grid positions for ground grid lines
    final nWg = result.grid.widthBays;
    final nLg = result.grid.lengthBays;
    final psg = result.poleSize;
    final gridX = List<double>.generate(nWg + 1, (i) => (i * psg).clamp(0.0, result.plotWidth));
    final gridZ = List<double>.generate(nLg + 1, (j) => (j * psg).clamp(0.0, result.plotLength));

    for (int i = 0; i <= nWg; i++) {
      final p1 = project(v64.Vector3(gridX[i], 0, 0));
      final p2 = project(v64.Vector3(gridX[i], 0, result.plotLength));
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, i == 0 || i == nWg ? boundaryPaint : gridPaint);
    }
    
    for (int j = 0; j <= nLg; j++) {
      final p1 = project(v64.Vector3(0, 0, gridZ[j]));
      final p2 = project(v64.Vector3(result.plotWidth, 0, gridZ[j]));
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, j == 0 || j == nLg ? boundaryPaint : gridPaint);
    }

    // Sort Layout Points by Z depth for proper rendering order
    final cameraZDir = v64.Vector3(eyeOffset.x, eyeOffset.y, eyeOffset.z)..normalize();
    final sortedPoints = List<PoleLayoutPoint>.from(result.poleLayoutPoints)
      ..sort((a, b) {
         final vecA = v64.Vector3(a.x, 0, a.z) - eyePosition;
         final vecB = v64.Vector3(b.x, 0, b.z) - eyePosition;
         return vecA.dot(cameraZDir).compareTo(vecB.dot(cameraZDir)); // Draw furthest first
      });

    final chordPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
      
    final basePlatePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;
      
    final pipePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final height = result.poleSize;

    // Draw Vertical Poles and Base Plates
    for (final point in sortedPoints) {
      final bx = point.x;
      final bz = point.z;

      final pBase = project(v64.Vector3(bx, 0.0, bz));
      final pTop = project(v64.Vector3(bx, height, bz));
      
      if (pBase != null && pTop != null) {
         // Base Plate (small diamond)
         final plateSize = 4.0;
         final path = Path()
           ..moveTo(pBase.dx - plateSize, pBase.dy)
           ..lineTo(pBase.dx, pBase.dy - plateSize * 0.5)
           ..lineTo(pBase.dx + plateSize, pBase.dy)
           ..lineTo(pBase.dx, pBase.dy + plateSize * 0.5)
           ..close();
         canvas.drawPath(path, basePlatePaint);
         
         // Vertical Pole
         canvas.drawLine(pBase, pTop, chordPaint);
      }
    }
    
    // Build a 2D grid of actual pole positions (nWidth+1 columns, nLength+1 rows)
    // using the same clamp logic as the domain service so pipes align exactly with poles.
    final nW = result.grid.widthBays;
    final nL = result.grid.lengthBays;
    final ps = result.poleSize;

    // poleX[i] = actual X position of column i
    final poleX = List<double>.generate(nW + 1, (i) => (i * ps).clamp(0.0, result.plotWidth));
    // poleZ[j] = actual Z position of row j
    final poleZ = List<double>.generate(nL + 1, (j) => (j * ps).clamp(0.0, result.plotLength));

    // Draw Horizontal Pipes (along width direction, connecting columns within each row)
    for (int j = 0; j <= nL; j++) {
      for (int i = 0; i < nW; i++) {
        final p1 = project(v64.Vector3(poleX[i],     height, poleZ[j]));
        final p2 = project(v64.Vector3(poleX[i + 1], height, poleZ[j]));
        if (p1 != null && p2 != null) canvas.drawLine(p1, p2, pipePaint);
      }
    }

    // Draw Horizontal Pipes (along length direction, connecting rows within each column)
    for (int i = 0; i <= nW; i++) {
      for (int j = 0; j < nL; j++) {
        final p1 = project(v64.Vector3(poleX[i], height, poleZ[j]));
        final p2 = project(v64.Vector3(poleX[i], height, poleZ[j + 1]));
        if (p1 != null && p2 != null) canvas.drawLine(p1, p2, pipePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Pole3DPainter oldDelegate) {
    return oldDelegate.result != result ||
           oldDelegate.cameraAzimuth != cameraAzimuth ||
           oldDelegate.cameraElevation != cameraElevation ||
           oldDelegate.cameraZoom != cameraZoom;
  }
}
