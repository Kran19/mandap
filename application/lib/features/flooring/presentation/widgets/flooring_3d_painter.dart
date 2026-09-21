import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/flooring_calculation_result.dart';
import '../../domain/models/flooring_carpet.dart';
import '../flooring_calculator_controller.dart';
import '../../../mandap/presentation/widgets/3d/environment/festival_world_environment.dart';

class Flooring3DPainter extends CustomPainter {
  final FlooringCalculationResult result;
  final FlooringCalculatorController controller;
  final double animationProgress;

  Flooring3DPainter({
    required this.result,
    required this.controller,
    this.animationProgress = 1.0,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0 || result.plotLength <= 0 || result.plotWidth <= 0) return;

    // 0. Screen-Space Atmospheric Sky Backdrop (Identical to Truss, Pole, & Stage)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6BA3D6),
          Color(0xFF90C2E7),
          Color(0xFFC7E2F5),
          Color(0xFFE8F2FA),
        ],
        stops: [0.0, 0.40, 0.75, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final centerTarget = controller.cameraCenterTarget;
    final maxDim = math.max(result.coveredLength, result.coveredWidth);
    final distance = math.max(maxDim * 2.2, 40.0) * controller.cameraZoom;

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

    // 1. World-Space 3D Festival & Live Event Background Environment
    FestivalWorldEnvironment.paint(
      canvas: canvas,
      size: size,
      project: project,
      eyePosition: eyePosition,
      plotWidth: result.coveredLength,
      plotDepth: result.coveredWidth,
      minX: 0.0,
      minZ: 0.0,
    );

    // Animation Stage 1: Ground Shadow & Boundary Setup (0.00 - 0.20)
    final shadowProgress = (animationProgress / 0.20).clamp(0.0, 1.0);
    if (shadowProgress > 0.0) {
      final shadowAlpha = (0x66 * shadowProgress).round();
      final shadowPaint = Paint()
        ..color = Color.fromARGB(shadowAlpha, 0x0B, 0x18, 0x0B)
        ..style = PaintingStyle.fill;

      final sMargin = 1.2 * shadowProgress;
      final sp1 = project(v64.Vector3(-sMargin, 0.008, -sMargin));
      final sp2 = project(v64.Vector3(result.coveredLength + sMargin, 0.008, -sMargin));
      final sp3 = project(v64.Vector3(result.coveredLength + sMargin, 0.008, result.coveredWidth + sMargin));
      final sp4 = project(v64.Vector3(-sMargin, 0.008, result.coveredWidth + sMargin));
      if (sp1 != null && sp2 != null && sp3 != null && sp4 != null) {
        final sPath = Path()
          ..moveTo(sp1.dx, sp1.dy)
          ..lineTo(sp2.dx, sp2.dy)
          ..lineTo(sp3.dx, sp3.dy)
          ..lineTo(sp4.dx, sp4.dy)
          ..close();
        canvas.drawPath(sPath, shadowPaint);
      }
    }

    // Animation Stage 2: Carpet Rollout (0.15 - 0.75)
    // Animation Stage 3: Detailing & Gold Trim (0.75 - 1.00)
    final carpetOverallProgress = ((animationProgress - 0.15) / 0.60).clamp(0.0, 1.0);
    final detailProgress = ((animationProgress - 0.75) / 0.25).clamp(0.0, 1.0);

    if (carpetOverallProgress > 0.0) {
      // 3. Sort Carpet Pieces back-to-front by distance to camera
      final cameraZDir = (controller.cameraCenterTarget - eyePosition)..normalize();
      final sortedCarpets = List<FlooringCarpet>.from(result.carpetLayout)
        ..sort((a, b) {
          final centerA = v64.Vector3(a.x + a.width / 2, 0.02, a.z + a.depth / 2);
          final centerB = v64.Vector3(b.x + b.width / 2, 0.02, b.z + b.depth / 2);
          final vecA = centerA - eyePosition;
          final vecB = centerB - eyePosition;
          return vecB.dot(cameraZDir).compareTo(vecA.dot(cameraZDir));
        });

      final totalSpan = math.max(1.0, result.coveredLength + result.coveredWidth);

      for (final carpet in sortedCarpets) {
        // Individual carpet unrolling progress based on floor position
        final posFraction = ((carpet.x + carpet.z) / totalSpan).clamp(0.0, 0.85);
        final carpetStart = posFraction * 0.55;
        final carpetEnd = (carpetStart + 0.45).clamp(0.0, 1.0);
        final pieceProgress = ((carpetOverallProgress - carpetStart) / (carpetEnd - carpetStart)).clamp(0.0, 1.0);

        if (pieceProgress <= 0.0) continue;

        // Unroll carpet along depth/length
        final curDepth = carpet.depth * pieceProgress;
        const carpetY = 0.02;
        const patternY = 0.025;

        final c0 = project(v64.Vector3(carpet.x, carpetY, carpet.z));
        final c1 = project(v64.Vector3(carpet.x + carpet.width, carpetY, carpet.z));
        final c2 = project(v64.Vector3(carpet.x + carpet.width, carpetY, carpet.z + curDepth));
        final c3 = project(v64.Vector3(carpet.x, carpetY, carpet.z + curDepth));

        if (c0 != null && c1 != null && c2 != null && c3 != null) {
          final carpetPath = Path()
            ..moveTo(c0.dx, c0.dy)
            ..lineTo(c1.dx, c1.dy)
            ..lineTo(c2.dx, c2.dy)
            ..lineTo(c3.dx, c3.dy)
            ..close();

          // Dual-Tone Checker Weave with opacity transition
          final colIdx = (carpet.x / (carpet.width > 0 ? carpet.width : 1.0)).round();
          final rowIdx = (carpet.z / (carpet.depth > 0 ? carpet.depth : 1.0)).round();
          final isToneA = (colIdx + rowIdx) % 2 == 0;

          // Uniform Ceremonial Crimson for all carpets
          final Color carpetColor = isToneA ? const Color(0xFF991B1B) : const Color(0xFF7F1D1D);

          final carpetPaint = Paint()
            ..color = carpetColor.withValues(alpha: pieceProgress.clamp(0.3, 1.0))
            ..style = PaintingStyle.fill;
          canvas.drawPath(carpetPath, carpetPaint);

          const Color seamColor = Color(0xFF450A0A);

          final seamPaint = Paint()
            ..color = seamColor.withValues(alpha: pieceProgress)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          canvas.drawPath(carpetPath, seamPaint);

          // Once piece is fully unrolled, fade in borders & motifs as detailing progresses
          if (pieceProgress >= 0.95 && detailProgress > 0.0) {
            const Color motifColor = Color(0xFFF59E0B);

            final goldBorderPaint = Paint()
              ..color = motifColor.withValues(alpha: detailProgress)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4;
            final diamondMotifPaint = Paint()
              ..color = motifColor.withValues(alpha: detailProgress * 0.25)
              ..style = PaintingStyle.fill;

            // Decorative Inset Ceremonial Pattern Border
            final inX = math.min(0.8, carpet.width * 0.12);
            final inZ = math.min(0.8, carpet.depth * 0.12);

            final b0 = project(v64.Vector3(carpet.x + inX, patternY, carpet.z + inZ));
            final b1 = project(v64.Vector3(carpet.x + carpet.width - inX, patternY, carpet.z + inZ));
            final b2 = project(v64.Vector3(carpet.x + carpet.width - inX, patternY, carpet.z + carpet.depth - inZ));
            final b3 = project(v64.Vector3(carpet.x + inX, patternY, carpet.z + carpet.depth - inZ));

            if (b0 != null && b1 != null && b2 != null && b3 != null) {
              final borderPath = Path()
                ..moveTo(b0.dx, b0.dy)
                ..lineTo(b1.dx, b1.dy)
                ..lineTo(b2.dx, b2.dy)
                ..lineTo(b3.dx, b3.dy)
                ..close();
              canvas.drawPath(borderPath, goldBorderPaint);

              // Central Royal Diamond Motif
              final cX = carpet.x + carpet.width / 2;
              final cZ = carpet.z + carpet.depth / 2;
              final dR = math.min(carpet.width, carpet.depth) * 0.22;

              final dTop = project(v64.Vector3(cX, patternY, cZ - dR));
              final dRight = project(v64.Vector3(cX + dR, patternY, cZ));
              final dBottom = project(v64.Vector3(cX, patternY, cZ + dR));
              final dLeft = project(v64.Vector3(cX - dR, patternY, cZ));

              if (dTop != null && dRight != null && dBottom != null && dLeft != null) {
                final diamondPath = Path()
                  ..moveTo(dTop.dx, dTop.dy)
                  ..lineTo(dRight.dx, dRight.dy)
                  ..lineTo(dBottom.dx, dBottom.dy)
                  ..lineTo(dLeft.dx, dLeft.dy)
                  ..close();
                canvas.drawPath(diamondPath, diamondMotifPaint);
                canvas.drawPath(diamondPath, goldBorderPaint);
              }

              // Sequential Carpet Number Badge (1, 2, 3... N)
              final midCenter = project(v64.Vector3(carpet.x + carpet.width / 2, 0.035, carpet.z + carpet.depth / 2));
              if (midCenter != null) {
                final tp = TextPainter(
                  text: TextSpan(
                    text: '${carpet.id + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 6.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();

                final numR = math.max(tp.width, tp.height) / 2.0 + 1.2;
                final badgeFill = Paint()
                  ..color = const Color(0xCC0F172A)
                  ..style = PaintingStyle.fill;
                final badgeBorder = Paint()
                  ..color = const Color(0xFFF59E0B)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 0.7;

                canvas.drawCircle(midCenter, numR, badgeFill);
                canvas.drawCircle(midCenter, numR, badgeBorder);
                tp.paint(canvas, Offset(midCenter.dx - tp.width / 2.0, midCenter.dy - tp.height / 2.0));
              }
            }
          }
        }
      }
    }


    // 4. Requested Plot Boundary & Out-of-Plot Overhang Visualization
    if (animationProgress >= 0.70) {
      const plotY = 0.035;
      final pl = result.plotLength;
      final pw = result.plotWidth;
      final cl = result.coveredLength;
      final cw = result.coveredWidth;

      // Full Requested Plot Boundary Rectangle
      final p0 = project(v64.Vector3(0, plotY, 0));
      final p1 = project(v64.Vector3(pl, plotY, 0));
      final p2 = project(v64.Vector3(pl, plotY, pw));
      final p3 = project(v64.Vector3(0, plotY, pw));

      if (p0 != null && p1 != null && p2 != null && p3 != null) {
        final plotPath = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();

        // Cyan glow halo
        canvas.drawPath(
          plotPath,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Crisp electric cyan plot boundary line
        canvas.drawPath(
          plotPath,
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      // Helper to draw architectural 3D dimension lines with extension lines, arrows, and dimension badges
      void draw3DDimensionLine({
        required v64.Vector3 startWorld,
        required v64.Vector3 endWorld,
        required String text,
        Color lineColor = const Color(0xFF00E5FF),
        Color badgeBg = const Color(0xEE0F172A),
        Color badgeBorder = const Color(0xFF00E5FF),
        Color textColor = Colors.white,
      }) {
        final pStart = project(startWorld);
        final pEnd = project(endWorld);
        if (pStart == null || pEnd == null) return;

        final linePaint = Paint()
          ..color = lineColor
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;

        // Main line
        canvas.drawLine(pStart, pEnd, linePaint);

        // Architectural Ticks / Arrows at endpoints
        final dir = pEnd - pStart;
        final dist = dir.distance;
        if (dist > 3.0) {
          final norm = Offset(dir.dx / dist, dir.dy / dist);
          final perp = Offset(-norm.dy, norm.dx) * 4.5;

          // End-tick perpendicular lines
          canvas.drawLine(pStart - perp, pStart + perp, linePaint);
          canvas.drawLine(pEnd - perp, pEnd + perp, linePaint);

          // Arrowheads
          final arrowArm1 = (-norm + Offset(-norm.dy, norm.dx) * 0.5) * 5.5;
          final arrowArm2 = (-norm - Offset(-norm.dy, norm.dx) * 0.5) * 5.5;
          canvas.drawLine(pEnd, pEnd + arrowArm1, linePaint);
          canvas.drawLine(pEnd, pEnd + arrowArm2, linePaint);

          final startArm1 = (norm + Offset(-norm.dy, norm.dx) * 0.5) * 5.5;
          final startArm2 = (norm - Offset(-norm.dy, norm.dx) * 0.5) * 5.5;
          canvas.drawLine(pStart, pStart + startArm1, linePaint);
          canvas.drawLine(pStart, pStart + startArm2, linePaint);
        }

        // Center dimension badge
        final mid = Offset((pStart.dx + pEnd.dx) / 2.0, (pStart.dy + pEnd.dy) / 2.0);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeW = tp.width + 12.0;
        final badgeH = tp.height + 6.0;
        final badgeRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: mid, width: badgeW, height: badgeH),
          const Radius.circular(5),
        );

        canvas.drawRRect(badgeRRect, Paint()..color = badgeBg);
        canvas.drawRRect(
          badgeRRect,
          Paint()
            ..color = badgeBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        tp.paint(canvas, Offset(mid.dx - tp.width / 2.0, mid.dy - tp.height / 2.0));
      }

      // Extension lines paint
      final extPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.40)
        ..strokeWidth = 1.0;
      final warnExtPaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.50)
        ..strokeWidth = 1.0;

      // Top extension lines for width (along X = -2.6)
      final extW0Start = project(v64.Vector3(0, plotY, 0));
      final extW0End = project(v64.Vector3(-3.2, plotY, 0));
      final extW1Start = project(v64.Vector3(0, plotY, pw));
      final extW1End = project(v64.Vector3(-3.2, plotY, pw));
      if (extW0Start != null && extW0End != null) canvas.drawLine(extW0Start, extW0End, extPaint);
      if (extW1Start != null && extW1End != null) canvas.drawLine(extW1Start, extW1End, extPaint);

      // Width Dimension Line
      draw3DDimensionLine(
        startWorld: v64.Vector3(-2.6, plotY, 0),
        endWorld: v64.Vector3(-2.6, plotY, pw),
        text: '${pw.toInt()} ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBorder: const Color(0xFF00E5FF),
      );

      // Extra Width Dimension Line (if any)
      if (cw > pw) {
        final extW2Start = project(v64.Vector3(0, plotY, cw));
        final extW2End = project(v64.Vector3(-3.2, plotY, cw));
        if (extW2Start != null && extW2End != null) canvas.drawLine(extW2Start, extW2End, warnExtPaint);

        final extraTextW = (cw - pw) % 1 == 0 ? (cw - pw).toStringAsFixed(0) : (cw - pw).toStringAsFixed(1);
        draw3DDimensionLine(
          startWorld: v64.Vector3(-2.6, plotY, pw),
          endWorld: v64.Vector3(-2.6, plotY, cw),
          text: '⚠ $extraTextW ft Extra',
          lineColor: const Color(0xFFF59E0B),
          badgeBg: const Color(0xFF78350F),
          badgeBorder: const Color(0xFFFBBF24),
          textColor: const Color(0xFFFDE047),
        );
      }

      // Right extension lines for length (along Z = -2.6)
      final extL0Start = project(v64.Vector3(0, plotY, 0));
      final extL0End = project(v64.Vector3(0, plotY, -3.2));
      final extL1Start = project(v64.Vector3(pl, plotY, 0));
      final extL1End = project(v64.Vector3(pl, plotY, -3.2));
      if (extL0Start != null && extL0End != null) canvas.drawLine(extL0Start, extL0End, extPaint);
      if (extL1Start != null && extL1End != null) canvas.drawLine(extL1Start, extL1End, extPaint);

      // Length Dimension Line
      draw3DDimensionLine(
        startWorld: v64.Vector3(0, plotY, -2.6),
        endWorld: v64.Vector3(pl, plotY, -2.6),
        text: '${pl.toInt()} ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBorder: const Color(0xFF00E5FF),
      );

      // Extra Length Dimension Line (if any)
      if (cl > pl) {
        final extL2Start = project(v64.Vector3(cl, plotY, 0));
        final extL2End = project(v64.Vector3(cl, plotY, -3.2));
        if (extL2Start != null && extL2End != null) canvas.drawLine(extL2Start, extL2End, warnExtPaint);

        final extraTextL = (cl - pl) % 1 == 0 ? (cl - pl).toStringAsFixed(0) : (cl - pl).toStringAsFixed(1);
        draw3DDimensionLine(
          startWorld: v64.Vector3(pl, plotY, -2.6),
          endWorld: v64.Vector3(cl, plotY, -2.6),
          text: '⚠ $extraTextL ft Extra',
          lineColor: const Color(0xFFF59E0B),
          badgeBg: const Color(0xFF78350F),
          badgeBorder: const Color(0xFFFBBF24),
          textColor: const Color(0xFFFDE047),
        );
      }

      // Helper to draw in-model 3D callout badges
      void drawCalloutBadge({
        required Offset center,
        required String title,
        required String subtitle,
      }) {
        final titleSpan = TextSpan(
          text: title,
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        );
        final subSpan = TextSpan(
          text: subtitle,
          style: const TextStyle(
            color: Color(0xFFFDE047), // Vivid Yellow/Amber warning
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
          ),
        );

        final tp1 = TextPainter(text: titleSpan, textDirection: TextDirection.ltr)..layout();
        final tp2 = TextPainter(text: subSpan, textDirection: TextDirection.ltr)..layout();

        final badgeW = math.max(tp1.width, tp2.width) + 18.0;
        final badgeH = tp1.height + tp2.height + 10.0;

        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: badgeW, height: badgeH),
          const Radius.circular(6),
        );

        // Semi-translucent dark slate background with cyan border
        canvas.drawRRect(badgeRect, Paint()..color = const Color(0xEE0F172A));
        canvas.drawRRect(
          badgeRect,
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );

        tp1.paint(canvas, Offset(center.dx - tp1.width / 2.0, center.dy - badgeH / 2.0 + 4.0));
        tp2.paint(canvas, Offset(center.dx - tp2.width / 2.0, center.dy - badgeH / 2.0 + 5.0 + tp1.height));
      }

      // A. If Flooring goes OUT of Plot along Length (cl > pl)
      if (cl > pl) {
        final excessL = cl - pl;
        final extraSqFt = (excessL * cw).round();

        // 1. Shaded warning tint over the excess carpet overhang
        final e0 = project(v64.Vector3(pl, 0.036, 0));
        final e1 = project(v64.Vector3(cl, 0.036, 0));
        final e2 = project(v64.Vector3(cl, 0.036, cw));
        final e3 = project(v64.Vector3(pl, 0.036, cw));

        if (e0 != null && e1 != null && e2 != null && e3 != null) {
          final ePath = Path()
            ..moveTo(e0.dx, e0.dy)
            ..lineTo(e1.dx, e1.dy)
            ..lineTo(e2.dx, e2.dy)
            ..lineTo(e3.dx, e3.dy)
            ..close();

          canvas.drawPath(ePath, Paint()..color = const Color(0x3AF59E0B)); // Amber warning wash
          canvas.drawPath(
            ePath,
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        }

        // 2. High-visibility Electric Cyan Cut-off Boundary Line right across the carpet
        final cutStart = project(v64.Vector3(pl, 0.040, 0));
        final cutEnd = project(v64.Vector3(pl, 0.040, cw));
        final cutMid = project(v64.Vector3(pl, 0.045, cw / 2.0));

        if (cutStart != null && cutEnd != null) {
          // Luminous cyan glow
          canvas.drawLine(
            cutStart,
            cutEnd,
            Paint()
              ..color = const Color(0xFF00F0FF).withValues(alpha: 0.50)
              ..strokeWidth = 8.0
              ..strokeCap = StrokeCap.round,
          );
          // Solid cyan core line
          canvas.drawLine(
            cutStart,
            cutEnd,
            Paint()
              ..color = const Color(0xFF00F0FF)
              ..strokeWidth = 3.6
              ..strokeCap = StrokeCap.round,
          );

          // End pin dots
          canvas.drawCircle(cutStart, 5.0, Paint()..color = const Color(0xFF00F0FF));
          canvas.drawCircle(cutEnd, 5.0, Paint()..color = const Color(0xFF00F0FF));
          canvas.drawCircle(cutStart, 2.5, Paint()..color = Colors.white);
          canvas.drawCircle(cutEnd, 2.5, Paint()..color = Colors.white);
        }

        // 3. 3D In-Model Overhang Badge
        if (cutMid != null) {
          final extraText = excessL % 1 == 0 ? excessL.toStringAsFixed(0) : excessL.toStringAsFixed(1);
          drawCalloutBadge(
            center: Offset(cutMid.dx, cutMid.dy - 18),
            title: 'Plot Limit: ${pl.toInt()} ft',
            subtitle: '⚠ $extraText ft Extra ($extraSqFt sq ft)',
          );
        }
      }

      // B. If Flooring goes OUT of Plot along Width (cw > pw)
      if (cw > pw) {
        final excessW = cw - pw;
        final extraSqFt = (excessW * cl).round();

        final w0 = project(v64.Vector3(0, 0.036, pw));
        final w1 = project(v64.Vector3(cl, 0.036, pw));
        final w2 = project(v64.Vector3(cl, 0.036, cw));
        final w3 = project(v64.Vector3(0, 0.036, cw));

        if (w0 != null && w1 != null && w2 != null && w3 != null) {
          final wPath = Path()
            ..moveTo(w0.dx, w0.dy)
            ..lineTo(w1.dx, w1.dy)
            ..lineTo(w2.dx, w2.dy)
            ..lineTo(w3.dx, w3.dy)
            ..close();

          canvas.drawPath(wPath, Paint()..color = const Color(0x3AF59E0B));
          canvas.drawPath(
            wPath,
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        }

        final wCutStart = project(v64.Vector3(0, 0.040, pw));
        final wCutEnd = project(v64.Vector3(cl, 0.040, pw));
        final wCutMid = project(v64.Vector3(cl / 2.0, 0.045, pw));

        if (wCutStart != null && wCutEnd != null) {
          canvas.drawLine(
            wCutStart,
            wCutEnd,
            Paint()
              ..color = const Color(0xFF00F0FF).withValues(alpha: 0.50)
              ..strokeWidth = 8.0
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawLine(
            wCutStart,
            wCutEnd,
            Paint()
              ..color = const Color(0xFF00F0FF)
              ..strokeWidth = 3.6
              ..strokeCap = StrokeCap.round,
          );

          canvas.drawCircle(wCutStart, 5.0, Paint()..color = const Color(0xFF00F0FF));
          canvas.drawCircle(wCutEnd, 5.0, Paint()..color = const Color(0xFF00F0FF));
          canvas.drawCircle(wCutStart, 2.5, Paint()..color = Colors.white);
          canvas.drawCircle(wCutEnd, 2.5, Paint()..color = Colors.white);
        }

        if (wCutMid != null) {
          final extraTextW = excessW % 1 == 0 ? excessW.toStringAsFixed(0) : excessW.toStringAsFixed(1);
          drawCalloutBadge(
            center: Offset(wCutMid.dx, wCutMid.dy - 18),
            title: 'Plot Limit: ${pw.toInt()} ft',
            subtitle: '⚠ $extraTextW ft Extra ($extraSqFt sq ft)',
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant Flooring3DPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.controller != controller ||
        oldDelegate.animationProgress != animationProgress;
  }
}
