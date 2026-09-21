import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/pole_calculation_result.dart';
import '../../domain/models/pole_layout_point.dart';
import '../pole_calculator_controller.dart';
import '../../../mandap/presentation/widgets/3d/environment/festival_world_environment.dart';

class Pole3DPainter extends CustomPainter {
  final PoleCalculationResult result;
  final PoleCalculatorController controller;
  final double animationProgress;

  Pole3DPainter({
    required this.result,
    required this.controller,
    this.animationProgress = 1.0,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0 || result.plotLength <= 0 || result.plotWidth <= 0) return;

    // 0. Sky Backdrop
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7FAAD0),
          Color(0xFFB8D5ED),
          Color(0xFFD6E6F5),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final centerTarget = controller.cameraCenterTarget;
    final maxDim = math.max(result.plotWidth, result.plotLength);
    final distance = math.max(maxDim * 2.3, 60.0) * controller.cameraZoom;

    final cosElev = math.cos(controller.cameraElevation);
    final sinElev = math.sin(controller.cameraElevation);
    final cosAzim = math.cos(controller.cameraAzimuth);
    final sinAzim = math.sin(controller.cameraAzimuth);

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
      2500.0,
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

    // 1. Paint World Environment (Grass turf, boundary fence, gate, red carpet, trees)
    _paintWorldEnvironment(canvas, size, project, eyePosition);

    // 2. Paint Structure (Poles & Pipes)
    _paintStructure(canvas, project, eyePosition);
  }

  void _paintWorldEnvironment(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
    v64.Vector3 eyePosition,
  ) {
    final minX = 0.0;
    final maxX = result.plotWidth;
    final minZ = 0.0;
    final maxZ = result.plotLength;

    final plotW = maxX - minX;
    final plotD = maxZ - minZ;

    // 1. Delegate to the Festival Live Event World Environment
    FestivalWorldEnvironment.paint(
      canvas: canvas,
      size: size,
      project: project,
      eyePosition: eyePosition,
      plotWidth: plotW,
      plotDepth: plotD,
      minX: minX,
      minZ: minZ,
    );

    // 2. Ground-contact shadows beneath all poles
    final shadowPaint = Paint()
      ..color = const Color(0x660B180B)
      ..style = PaintingStyle.fill;
    for (final pt in result.poleLayoutPoints) {
      final bx = pt.x;
      final bz = pt.z;
      const sRad = 1.8;
      final sp1 = project(v64.Vector3(bx - sRad, 0.015, bz - sRad));
      final sp2 = project(v64.Vector3(bx + sRad, 0.015, bz - sRad));
      final sp3 = project(v64.Vector3(bx + sRad, 0.015, bz + sRad));
      final sp4 = project(v64.Vector3(bx - sRad, 0.015, bz + sRad));
      if (sp1 != null && sp2 != null && sp3 != null && sp4 != null) {
        final shadowPath = Path()
          ..moveTo(sp1.dx, sp1.dy)
          ..lineTo(sp2.dx, sp2.dy)
          ..lineTo(sp3.dx, sp3.dy)
          ..lineTo(sp4.dx, sp4.dy)
          ..close();
        canvas.drawPath(shadowPath, shadowPaint);
      }
    }
  }

  void _paintStructure(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    v64.Vector3 eyePosition,
  ) {
    final height = result.poleSize > 0 ? result.poleSize : 15.0;

    // Sorting points for depth
    final cameraZDir = (controller.cameraCenterTarget - eyePosition)..normalize();
    final sortedPoints = List<PoleLayoutPoint>.from(result.poleLayoutPoints)
      ..sort((a, b) {
        final vecA = v64.Vector3(a.x, 0, a.z) - eyePosition;
        final vecB = v64.Vector3(b.x, 0, b.z) - eyePosition;
        return vecA.dot(cameraZDir).compareTo(vecB.dot(cameraZDir));
      });

    final poleHighlight = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final poleCore = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final basePlatePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final basePlateBorder = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pipeHighlight = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final pipeCore = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final couplerPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    // Progressive construction animation stages:
    // 0.00 - 0.15: Base plates expand on ground
    // 0.15 - 0.60: Vertical poles rise up to full height
    // 0.60 - 1.00: Top couplers and horizontal pipes lock in place
    final baseProgress = (animationProgress / 0.15).clamp(0.0, 1.0);
    final poleProgress = ((animationProgress - 0.15) / 0.45).clamp(0.0, 1.0);
    final pipeProgress = ((animationProgress - 0.60) / 0.40).clamp(0.0, 1.0);

    final currentHeight = height * poleProgress;

    // 1. Draw Vertical Poles and Base Plates
    for (final point in sortedPoints) {
      final bx = point.x;
      final bz = point.z;

      final pBase = project(v64.Vector3(bx, 0.0, bz));
      final pTop = project(v64.Vector3(bx, currentHeight, bz));
      final pFullTop = project(v64.Vector3(bx, height, bz));

      if (pBase != null && baseProgress > 0) {
        // Base plate (square diamond)
        final plateSize = 6.0 * baseProgress;
        final path = Path()
          ..moveTo(pBase.dx - plateSize, pBase.dy)
          ..lineTo(pBase.dx, pBase.dy - plateSize * 0.5)
          ..lineTo(pBase.dx + plateSize, pBase.dy)
          ..lineTo(pBase.dx, pBase.dy + plateSize * 0.5)
          ..close();
        canvas.drawPath(path, basePlatePaint);
        canvas.drawPath(path, basePlateBorder);
      }

      if (pBase != null && pTop != null && currentHeight > 0.1) {
        // Vertical Pole (Dual-tone metallic steel chord rising)
        canvas.drawLine(pBase, pTop, poleHighlight);
        canvas.drawLine(pBase, pTop, poleCore);

        // Top Coupler Junction appears once pole reaches full height
        if (poleProgress >= 0.95 && pFullTop != null) {
          canvas.drawCircle(pFullTop, 4.5, couplerPaint);
          canvas.drawCircle(pFullTop, 3.0, poleHighlight);
        }
      }
    }

    // 2. Draw Horizontal Pipes along width & length (sweeps into place)
    if (pipeProgress <= 0.0) return;

    final nW = result.grid.widthBays;
    final nL = result.grid.lengthBays;
    final ps = result.poleSize;

    final poleX = List<double>.generate(nW + 1, (i) => (i * ps).clamp(0.0, result.plotWidth));
    final poleZ = List<double>.generate(nL + 1, (j) => (j * ps).clamp(0.0, result.plotLength));

    // Along width direction (X lines)
    for (int j = 0; j <= nL; j++) {
      for (int i = 0; i < nW; i++) {
        final p1 = project(v64.Vector3(poleX[i], height, poleZ[j]));
        final endVec = v64.Vector3(
          poleX[i] + (poleX[i + 1] - poleX[i]) * pipeProgress,
          height,
          poleZ[j],
        );
        final p2 = project(endVec);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, pipeHighlight);
          canvas.drawLine(p1, p2, pipeCore);
        }
      }
    }

    // Along length direction (Z lines)
    for (int i = 0; i <= nW; i++) {
      for (int j = 0; j < nL; j++) {
        final p1 = project(v64.Vector3(poleX[i], height, poleZ[j]));
        final endVec = v64.Vector3(
          poleX[i],
          height,
          poleZ[j] + (poleZ[j + 1] - poleZ[j]) * pipeProgress,
        );
        final p2 = project(endVec);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, pipeHighlight);
          canvas.drawLine(p1, p2, pipeCore);
        }
      }
    }

    // 3. Draw Bay / Room Numbers (1, 2, 3...) in the center of each grid cell
    int bayNum = 1;
    final badgeBgPaint = Paint()
      ..color = const Color(0xD90F172A)
      ..style = PaintingStyle.fill;
    final badgeBorderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int j = 0; j < nL; j++) {
      for (int i = 0; i < nW; i++) {
        final xMid = (poleX[i] + poleX[i + 1]) / 2.0;
        final zMid = (poleZ[j] + poleZ[j + 1]) / 2.0;
        final p = project(v64.Vector3(xMid, 0.05, zMid));
        if (p != null) {
          final tp = TextPainter(
            text: TextSpan(
              text: '$bayNum',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final r = math.max(tp.width, tp.height) / 2.0 + 2.0;
          canvas.drawCircle(p, r, badgeBgPaint);
          canvas.drawCircle(p, r, badgeBorderPaint);
          tp.paint(canvas, Offset(p.dx - tp.width / 2.0, p.dy - tp.height / 2.0));
        }
        bayNum++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant Pole3DPainter oldDelegate) {
    return true;
  }
}
