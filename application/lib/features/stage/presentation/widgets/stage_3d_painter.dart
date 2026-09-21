import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/stage_calculation_result.dart';
import '../../domain/models/stage_table.dart';
import '../stage_calculator_controller.dart';
import '../../../mandap/presentation/widgets/3d/environment/festival_world_environment.dart';

class Stage3DPainter extends CustomPainter {
  final StageCalculationResult result;
  final StageCalculatorController controller;
  final double animationProgress;

  Stage3DPainter({
    required this.result,
    required this.controller,
    this.animationProgress = 1.0,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0 || result.stageLength <= 0 || result.stageWidth <= 0) return;

    // 0. Screen-Space Atmospheric Sky Backdrop (Identical to Truss & Pole)
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
    final maxDim = math.max(math.max(result.coveredLength, result.coveredWidth), result.stageHeight * 3);
    final distance = math.max(maxDim * 2.2, 50.0) * controller.cameraZoom;

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

    // 2. Collect deduplicated leg support positions (X, Z) at table corners
    final Set<String> legKeys = {};
    final List<v64.Vector2> legPositions = [];

    for (final table in result.tableLayoutPoints) {
      final corners = [
        v64.Vector2(table.x, table.z),
        v64.Vector2(table.x + table.width, table.z),
        v64.Vector2(table.x + table.width, table.z + table.depth),
        v64.Vector2(table.x, table.z + table.depth),
      ];
      for (final c in corners) {
        final key = '${c.x.toStringAsFixed(2)},${c.y.toStringAsFixed(2)}';
        if (!legKeys.contains(key)) {
          legKeys.add(key);
          legPositions.add(c);
        }
      }
    }

    // 3. Ground-Contact Shadows Beneath All Leg Posts / Base Plates (at Y = 0.015)
    final shadowPaint = Paint()
      ..color = const Color(0x660B180B)
      ..style = PaintingStyle.fill;

    for (final leg in legPositions) {
      const sRad = 1.2;
      final sp1 = project(v64.Vector3(leg.x - sRad, 0.015, leg.y - sRad));
      final sp2 = project(v64.Vector3(leg.x + sRad, 0.015, leg.y - sRad));
      final sp3 = project(v64.Vector3(leg.x + sRad, 0.015, leg.y + sRad));
      final sp4 = project(v64.Vector3(leg.x - sRad, 0.015, leg.y + sRad));
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

    // Depth sort elements (legs & tables) back-to-front
    final cameraZDir = (controller.cameraCenterTarget - eyePosition)..normalize();

    // 4. Draw Leg Supports (Metallic Posts + Square Ground Base Plates)
    final legPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final bracePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.5;

    final basePlatePaint = Paint()
      ..color = const Color(0xFF252A2F)
      ..style = PaintingStyle.fill;
    final basePlateBorder = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Progressive construction animation phases:
    // 0.00 - 0.20: Base plates on ground
    // 0.20 - 0.55: Support legs rising
    // 0.55 - 0.75: Under-deck diagonal braces
    // 0.75 - 1.00: Deck tables & crimson surface
    final baseProgress = (animationProgress / 0.20).clamp(0.0, 1.0);
    final legProgress = ((animationProgress - 0.20) / 0.35).clamp(0.0, 1.0);
    final braceProgress = ((animationProgress - 0.55) / 0.20).clamp(0.0, 1.0);
    final deckProgress = ((animationProgress - 0.75) / 0.25).clamp(0.0, 1.0);

    final currentHeight = result.stageHeight * legProgress;

    legPositions.sort((a, b) {
      final vecA = v64.Vector3(a.x, 0, a.y) - eyePosition;
      final vecB = v64.Vector3(b.x, 0, b.y) - eyePosition;
      return vecA.dot(cameraZDir).compareTo(vecB.dot(cameraZDir));
    });

    for (final leg in legPositions) {
      final bPos = v64.Vector3(leg.x, 0, leg.y);
      final tPos = v64.Vector3(leg.x, currentHeight, leg.y);

      final pBase = project(bPos);
      final pTop = project(tPos);

      if (pBase != null) {
        if (baseProgress > 0) {
          // Square ground base plate
          final pSize = 0.6 * baseProgress;
          final bp1 = project(v64.Vector3(leg.x - pSize, 0.02, leg.y - pSize));
          final bp2 = project(v64.Vector3(leg.x + pSize, 0.02, leg.y - pSize));
          final bp3 = project(v64.Vector3(leg.x + pSize, 0.02, leg.y + pSize));
          final bp4 = project(v64.Vector3(leg.x - pSize, 0.02, leg.y + pSize));
          if (bp1 != null && bp2 != null && bp3 != null && bp4 != null) {
            final platePath = Path()
              ..moveTo(bp1.dx, bp1.dy)
              ..lineTo(bp2.dx, bp2.dy)
              ..lineTo(bp3.dx, bp3.dy)
              ..lineTo(bp4.dx, bp4.dy)
              ..close();
            canvas.drawPath(platePath, basePlatePaint);
            canvas.drawPath(platePath, basePlateBorder);
          }
        }

        // Leg pole rising up to stage height
        if (pTop != null && currentHeight > 0.05) {
          canvas.drawLine(pBase, pTop, legPaint);
        }
      }
    }

    // Draw Under-Deck Diagonal Bracing per table panel
    if (braceProgress > 0) {
      for (final table in result.tableLayoutPoints) {
        final p1 = project(v64.Vector3(table.x, 0.1, table.z));
        final endBrace = v64.Vector3(
          table.x + table.width * braceProgress,
          result.stageHeight * braceProgress,
          table.z + table.depth * braceProgress,
        );
        final p2 = project(endBrace);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, bracePaint);
        }
      }
    }

    // 5. Draw Stage Deck Tables (Sorted back-to-front)
    if (deckProgress <= 0) return;

    final sortedTables = List<StageTable>.from(result.tableLayoutPoints)
      ..sort((a, b) {
        final centerA = v64.Vector3(a.x + a.width / 2, result.stageHeight, a.z + a.depth / 2);
        final centerB = v64.Vector3(b.x + b.width / 2, result.stageHeight, b.z + b.depth / 2);
        final vecA = centerA - eyePosition;
        final vecB = centerB - eyePosition;
        return vecA.dot(cameraZDir).compareTo(vecB.dot(cameraZDir));
      });

    final deckTopPaint = Paint()
      ..color = const Color(0xFFB91C1C).withValues(alpha: deckProgress) // Professional Crimson deck top
      ..style = PaintingStyle.fill;

    final deckSeamPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: deckProgress) // Stage seam highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frameRimPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: deckProgress) // Silver aluminium deck rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final h = result.stageHeight;

    for (final table in sortedTables) {
      final c0 = project(v64.Vector3(table.x, h, table.z));
      final c1 = project(v64.Vector3(table.x + table.width, h, table.z));
      final c2 = project(v64.Vector3(table.x + table.width, h, table.z + table.depth));
      final c3 = project(v64.Vector3(table.x, h, table.z + table.depth));

      if (c0 != null && c1 != null && c2 != null && c3 != null) {
        final deckPath = Path()
          ..moveTo(c0.dx, c0.dy)
          ..lineTo(c1.dx, c1.dy)
          ..lineTo(c2.dx, c2.dy)
          ..lineTo(c3.dx, c3.dy)
          ..close();

        canvas.drawPath(deckPath, deckTopPaint);
        canvas.drawPath(deckPath, deckSeamPaint);
        canvas.drawPath(deckPath, frameRimPaint);
      }
    }

    // 5b. Draw Table Numbering (1, 2, 3... N) on each table deck
    for (final table in sortedTables) {
      final centerWorld = v64.Vector3(
        table.x + table.width / 2,
        h + 0.05,
        table.z + table.depth / 2,
      );
      final pCenter = project(centerWorld);
      if (pCenter != null) {
        final numSpan = TextSpan(
          text: '${table.id + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: numSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final numR = math.max(textPainter.width, textPainter.height) / 2.0 + 3.5;
        final badgeBgPaint = Paint()
          ..color = const Color(0xDD0F172A)
          ..style = PaintingStyle.fill;
        final badgeBorderPaint = Paint()
          ..color = const Color(0xFFF59E0B) // Gold accent border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawCircle(pCenter, numR, badgeBgPaint);
        canvas.drawCircle(pCenter, numR, badgeBorderPaint);

        textPainter.paint(
          canvas,
          Offset(
            pCenter.dx - textPainter.width / 2.0,
            pCenter.dy - textPainter.height / 2.0,
          ),
        );
      }
    }

    // 6. Draw Front Access Steps (Centered along front stage edge)
    const int stepCount = 4;
    final stairWidth = math.min(8.0, result.orientedTableLength);
    final stairStartX = (result.coveredLength - stairWidth) / 2;
    final stairZ = result.coveredWidth;

    final stairTreadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final stairStringerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int step = 0; step < stepCount; step++) {
      final stepY = result.stageHeight * (stepCount - 1 - step) / stepCount;
      final stepZ = stairZ + (step * 0.7);

      final s0 = project(v64.Vector3(stairStartX, stepY, stepZ));
      final s1 = project(v64.Vector3(stairStartX + stairWidth, stepY, stepZ));
      final s2 = project(v64.Vector3(stairStartX + stairWidth, stepY, stepZ + 0.7));
      final s3 = project(v64.Vector3(stairStartX, stepY, stepZ + 0.7));

      if (s0 != null && s1 != null && s2 != null && s3 != null) {
        final stepPath = Path()
          ..moveTo(s0.dx, s0.dy)
          ..lineTo(s1.dx, s1.dy)
          ..lineTo(s2.dx, s2.dy)
          ..lineTo(s3.dx, s3.dy)
          ..close();

        canvas.drawPath(stepPath, stairTreadPaint);
        canvas.drawPath(stepPath, stairStringerPaint);
      }
    }

    // 7. Requested Stage Limit Boundary & Overhang Visualization
    if (animationProgress >= 0.70) {
      final pl = result.stageLength;
      final pw = result.stageWidth;
      final cl = result.coveredLength;
      final cw = result.coveredWidth;
      final h = result.stageHeight;
      final deckY = h + 0.02;

      // Complete Electric Cyan Boundary Box on the stage deck surface (EXACTLY like Flooring)
      final p0 = project(v64.Vector3(0, deckY, 0));
      final p1 = project(v64.Vector3(pl, deckY, 0));
      final p2 = project(v64.Vector3(pl, deckY, pw));
      final p3 = project(v64.Vector3(0, deckY, pw));

      if (p0 != null && p1 != null && p2 != null && p3 != null) {
        final boxPath = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();

        // Luminous cyan glow halo
        canvas.drawPath(
          boxPath,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Crisp solid electric cyan boundary line completing the box
        canvas.drawPath(
          boxPath,
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
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
      final extW0Start = project(v64.Vector3(0, deckY, 0));
      final extW0End = project(v64.Vector3(-3.2, deckY, 0));
      final extW1Start = project(v64.Vector3(0, deckY, pw));
      final extW1End = project(v64.Vector3(-3.2, deckY, pw));
      if (extW0Start != null && extW0End != null) canvas.drawLine(extW0Start, extW0End, extPaint);
      if (extW1Start != null && extW1End != null) canvas.drawLine(extW1Start, extW1End, extPaint);

      // Width Dimension Line
      draw3DDimensionLine(
        startWorld: v64.Vector3(-2.6, deckY, 0),
        endWorld: v64.Vector3(-2.6, deckY, pw),
        text: '${pw.toInt()} ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBorder: const Color(0xFF00E5FF),
      );

      // Extra Width Dimension Line (if any)
      if (cw > pw) {
        final extW2Start = project(v64.Vector3(0, deckY, cw));
        final extW2End = project(v64.Vector3(-3.2, deckY, cw));
        if (extW2Start != null && extW2End != null) canvas.drawLine(extW2Start, extW2End, warnExtPaint);

        final extraTextW = (cw - pw) % 1 == 0 ? (cw - pw).toStringAsFixed(0) : (cw - pw).toStringAsFixed(1);
        draw3DDimensionLine(
          startWorld: v64.Vector3(-2.6, deckY, pw),
          endWorld: v64.Vector3(-2.6, deckY, cw),
          text: '⚠ $extraTextW ft Extra',
          lineColor: const Color(0xFFF59E0B),
          badgeBg: const Color(0xFF78350F),
          badgeBorder: const Color(0xFFFBBF24),
          textColor: const Color(0xFFFDE047),
        );
      }

      // Right extension lines for length (along Z = -2.6)
      final extL0Start = project(v64.Vector3(0, deckY, 0));
      final extL0End = project(v64.Vector3(0, deckY, -3.2));
      final extL1Start = project(v64.Vector3(pl, deckY, 0));
      final extL1End = project(v64.Vector3(pl, deckY, -3.2));
      if (extL0Start != null && extL0End != null) canvas.drawLine(extL0Start, extL0End, extPaint);
      if (extL1Start != null && extL1End != null) canvas.drawLine(extL1Start, extL1End, extPaint);

      // Length Dimension Line
      draw3DDimensionLine(
        startWorld: v64.Vector3(0, deckY, -2.6),
        endWorld: v64.Vector3(pl, deckY, -2.6),
        text: '${pl.toInt()} ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBorder: const Color(0xFF00E5FF),
      );

      // Extra Length Dimension Line (if any)
      if (cl > pl) {
        final extL2Start = project(v64.Vector3(cl, deckY, 0));
        final extL2End = project(v64.Vector3(cl, deckY, -3.2));
        if (extL2Start != null && extL2End != null) canvas.drawLine(extL2Start, extL2End, warnExtPaint);

        final extraTextL = (cl - pl) % 1 == 0 ? (cl - pl).toStringAsFixed(0) : (cl - pl).toStringAsFixed(1);
        draw3DDimensionLine(
          startWorld: v64.Vector3(pl, deckY, -2.6),
          endWorld: v64.Vector3(cl, deckY, -2.6),
          text: '⚠ $extraTextL ft Extra',
          lineColor: const Color(0xFFF59E0B),
          badgeBg: const Color(0xFF78350F),
          badgeBorder: const Color(0xFFFBBF24),
          textColor: const Color(0xFFFDE047),
        );
      }

      // Table Dimension Lines: Width on Table #2, Length on Table #18
      if (result.tableLayoutPoints.isNotEmpty) {
        final table2 = result.tableLayoutPoints.firstWhere(
          (t) => t.id == 1,
          orElse: () => result.tableLayoutPoints.first,
        );
        final table18 = result.tableLayoutPoints.firstWhere(
          (t) => t.id == 17,
          orElse: () => result.tableLayoutPoints.last,
        );

        final tLenStr = result.orientedTableLength % 1 == 0
            ? result.orientedTableLength.toInt().toString()
            : result.orientedTableLength.toStringAsFixed(1);
        final tWidStr = result.orientedTableWidth % 1 == 0
            ? result.orientedTableWidth.toInt().toString()
            : result.orientedTableWidth.toStringAsFixed(1);

        final tDeckY = h + 0.05;

        // Extension lines paint
        final tExtPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
          ..strokeWidth = 1.0;

        // 1. Width Dimension Line on Table #2 (horizontal across Z axis)
        final t2X = table2.x + table2.width * 0.35;
        final tExtW0Start = project(v64.Vector3(table2.x + table2.width * 0.15, tDeckY, table2.z));
        final tExtW0End = project(v64.Vector3(table2.x + table2.width * 0.55, tDeckY, table2.z));
        final tExtW1Start = project(v64.Vector3(table2.x + table2.width * 0.15, tDeckY, table2.z + table2.depth));
        final tExtW1End = project(v64.Vector3(table2.x + table2.width * 0.55, tDeckY, table2.z + table2.depth));
        if (tExtW0Start != null && tExtW0End != null) canvas.drawLine(tExtW0Start, tExtW0End, tExtPaint);
        if (tExtW1Start != null && tExtW1End != null) canvas.drawLine(tExtW1Start, tExtW1End, tExtPaint);

        draw3DDimensionLine(
          startWorld: v64.Vector3(t2X, tDeckY, table2.z),
          endWorld: v64.Vector3(t2X, tDeckY, table2.z + table2.depth),
          text: '$tWidStr ft',
          lineColor: const Color(0xFF00E5FF),
          badgeBg: const Color(0xFF0F172A),
          badgeBorder: const Color(0xFF00E5FF),
          textColor: const Color(0xFF00F0FF),
        );

        // 2. Length Dimension Line on Table #18 (vertical along X axis)
        final t18Z = table18.z + table18.depth * 0.35;
        final tExtL0Start = project(v64.Vector3(table18.x, tDeckY, table18.z + table18.depth * 0.15));
        final tExtL0End = project(v64.Vector3(table18.x, tDeckY, table18.z + table18.depth * 0.55));
        final tExtL1Start = project(v64.Vector3(table18.x + table18.width, tDeckY, table18.z + table18.depth * 0.15));
        final tExtL1End = project(v64.Vector3(table18.x + table18.width, tDeckY, table18.z + table18.depth * 0.55));
        if (tExtL0Start != null && tExtL0End != null) canvas.drawLine(tExtL0Start, tExtL0End, tExtPaint);
        if (tExtL1Start != null && tExtL1End != null) canvas.drawLine(tExtL1Start, tExtL1End, tExtPaint);

        draw3DDimensionLine(
          startWorld: v64.Vector3(table18.x, tDeckY, t18Z),
          endWorld: v64.Vector3(table18.x + table18.width, tDeckY, t18Z),
          text: '$tLenStr ft',
          lineColor: const Color(0xFF00E5FF),
          badgeBg: const Color(0xFF0F172A),
          badgeBorder: const Color(0xFF00E5FF),
          textColor: const Color(0xFF00F0FF),
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
            ..color = const Color(0xFF00F0FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );

        tp1.paint(canvas, Offset(center.dx - tp1.width / 2.0, center.dy - badgeH / 2.0 + 4.0));
        tp2.paint(canvas, Offset(center.dx - tp2.width / 2.0, center.dy - badgeH / 2.0 + 5.0 + tp1.height));
      }

      // A. If Stage goes OUT of requested limit along Length (cl > pl)
      if (cl > pl) {
        final excessL = cl - pl;
        final extraSqFt = (excessL * cw).round();
        final deckY = h + 0.02;

        // 1. Shaded warning tint & glowing highlight over the excess stage deck overhang
        final e0 = project(v64.Vector3(pl, deckY, 0));
        final e1 = project(v64.Vector3(cl, deckY, 0));
        final e2 = project(v64.Vector3(cl, deckY, cw));
        final e3 = project(v64.Vector3(pl, deckY, cw));

        if (e0 != null && e1 != null && e2 != null && e3 != null) {
          final ePath = Path()
            ..moveTo(e0.dx, e0.dy)
            ..lineTo(e1.dx, e1.dy)
            ..lineTo(e2.dx, e2.dy)
            ..lineTo(e3.dx, e3.dy)
            ..close();

          // Vibrant amber warning wash over deck
          canvas.drawPath(ePath, Paint()..color = const Color(0x55F59E0B));
          // Luminous amber glow stroke
          canvas.drawPath(
            ePath,
            Paint()
              ..color = const Color(0xFFF59E0B).withValues(alpha: 0.40)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0,
          );
          // Crisp highlighted amber border
          canvas.drawPath(
            ePath,
            Paint()
              ..color = const Color(0xFFFBBF24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }

        // 2. Highlight vertical front face of the excess overhang tables (3D depth)
        final f0 = project(v64.Vector3(cl, 0.015, 0));
        final f1 = project(v64.Vector3(cl, deckY, 0));
        final f2 = project(v64.Vector3(cl, deckY, cw));
        final f3 = project(v64.Vector3(cl, 0.015, cw));

        if (f0 != null && f1 != null && f2 != null && f3 != null) {
          final fPath = Path()
            ..moveTo(f0.dx, f0.dy)
            ..lineTo(f1.dx, f1.dy)
            ..lineTo(f2.dx, f2.dy)
            ..lineTo(f3.dx, f3.dy)
            ..close();
          canvas.drawPath(fPath, Paint()..color = const Color(0x40F59E0B));
          canvas.drawPath(
            fPath,
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }

        // 3. High-visibility Electric Cyan Cut-off Boundary Line right across the stage deck
        final cutStart = project(v64.Vector3(pl, deckY + 0.01, 0));
        final cutEnd = project(v64.Vector3(pl, deckY + 0.01, cw));
        final cutMid = project(v64.Vector3(pl, deckY + 0.02, cw / 2.0));

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

        // 4. 3D In-Model Overhang Badge
        if (cutMid != null) {
          final extraText = excessL % 1 == 0 ? excessL.toStringAsFixed(0) : excessL.toStringAsFixed(1);
          drawCalloutBadge(
            center: Offset(cutMid.dx, cutMid.dy - 18),
            title: 'Stage Limit: ${pl.toInt()} ft',
            subtitle: '⚠ $extraText ft Extra ($extraSqFt sq ft)',
          );
        }
      }

      // B. If Stage goes OUT of requested limit along Width (cw > pw)
      if (cw > pw) {
        final excessW = cw - pw;
        final extraSqFt = (excessW * cl).round();
        final deckY = h + 0.02;

        final w0 = project(v64.Vector3(0, deckY, pw));
        final w1 = project(v64.Vector3(cl, deckY, pw));
        final w2 = project(v64.Vector3(cl, deckY, cw));
        final w3 = project(v64.Vector3(0, deckY, cw));

        if (w0 != null && w1 != null && w2 != null && w3 != null) {
          final wPath = Path()
            ..moveTo(w0.dx, w0.dy)
            ..lineTo(w1.dx, w1.dy)
            ..lineTo(w2.dx, w2.dy)
            ..lineTo(w3.dx, w3.dy)
            ..close();

          canvas.drawPath(wPath, Paint()..color = const Color(0x55F59E0B));
          canvas.drawPath(
            wPath,
            Paint()
              ..color = const Color(0xFFF59E0B).withValues(alpha: 0.40)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0,
          );
          canvas.drawPath(
            wPath,
            Paint()
              ..color = const Color(0xFFFBBF24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }

        // Highlight vertical side face of excess width tables
        final s0 = project(v64.Vector3(0, 0.015, cw));
        final s1 = project(v64.Vector3(0, deckY, cw));
        final s2 = project(v64.Vector3(cl, deckY, cw));
        final s3 = project(v64.Vector3(cl, 0.015, cw));

        if (s0 != null && s1 != null && s2 != null && s3 != null) {
          final sPath = Path()
            ..moveTo(s0.dx, s0.dy)
            ..lineTo(s1.dx, s1.dy)
            ..lineTo(s2.dx, s2.dy)
            ..lineTo(s3.dx, s3.dy)
            ..close();
          canvas.drawPath(sPath, Paint()..color = const Color(0x40F59E0B));
          canvas.drawPath(
            sPath,
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }

        final wCutStart = project(v64.Vector3(0, deckY + 0.01, pw));
        final wCutEnd = project(v64.Vector3(cl, deckY + 0.01, pw));
        final wCutMid = project(v64.Vector3(cl / 2.0, deckY + 0.02, pw));

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
            title: 'Stage Limit: ${pw.toInt()} ft',
            subtitle: '⚠ $extraTextW ft Extra ($extraSqFt sq ft)',
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant Stage3DPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.controller != controller ||
        oldDelegate.animationProgress != animationProgress;
  }
}
