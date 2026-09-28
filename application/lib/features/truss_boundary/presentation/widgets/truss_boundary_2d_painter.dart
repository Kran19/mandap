import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/boundary_pole.dart';
import '../../domain/entities/boundary_side.dart';
import '../../domain/entities/boundary_truss_run.dart';
import '../../application/truss_boundary_controller.dart';

class TrussBoundary2dPainter extends CustomPainter {
  final Map<String, BoundarySide> fourSides;
  final List<BoundaryTrussRun> centerRuns;
  final List<BoundaryPole> uniquePoles;
  final double plotWidth;
  final double plotDepth;
  final EditingTool activeTool;
  final String? selectedSideId;
  final bool isCenterCrossActive;

  TrussBoundary2dPainter({
    required this.fourSides,
    required this.centerRuns,
    required this.uniquePoles,
    required this.plotWidth,
    required this.plotDepth,
    required this.activeTool,
    this.selectedSideId,
    this.isCenterCrossActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate transformation matrix to fit plot inside canvas with margin
    const margin = 40.0;
    final availWidth = size.width - margin * 2;
    final availHeight = size.height - margin * 2;
    if (availWidth <= 0 || availHeight <= 0) return;

    final scaleX = availWidth / plotWidth;
    final scaleZ = availHeight / plotDepth;
    final scale = math.min(scaleX, scaleZ);

    final offsetX = margin + (availWidth - plotWidth * scale) / 2;
    final offsetZ = margin + (availHeight - plotDepth * scale) / 2;

    Offset toCanvas(double x, double z) {
      return Offset(offsetX + x * scale, offsetZ + z * scale);
    }

    // 2. Draw Subtle Engineering Grid Lines
    _drawEngineeringGrid(canvas, size, scale, offsetX, offsetZ);

    // 3. Draw Plot Boundary (Electric Cyan Luminous Box matching Stage)
    final plotRect = Rect.fromPoints(toCanvas(0, 0), toCanvas(plotWidth, plotDepth));
    
    // Cyan glow halo
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Crisp solid cyan outline
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 4. Draw Truss Structural Runs (Box truss chords + lattice bracing)
    _drawPerimeterTrusses(canvas, scale, toCanvas);
    _drawCenterCrossTrusses(canvas, scale, toCanvas);

    // 5. Draw Center Light Target / Center Dot
    _drawCenterLightTarget(canvas, scale, toCanvas);

    // 6. Draw Graph-Style Visual Structural Nodes:
    //    🔴 Red Circle = Support Pole (as per truss logic / corners)
    //    ⚪ White Circle = Structural Joint (connection point)
    _drawStructuralNodes(canvas, toCanvas);

    // 7. Draw Stage-Type Architectural CAD Dimension Lines & Badges
    _drawStageTypeDimensionLines(canvas, plotRect, toCanvas, scale);

    // 8. Draw Compass Rose in corner (N, E, S, W)
    _drawCompass(canvas, size);
  }

  void _drawEngineeringGrid(Canvas canvas, Size size, double scale, double offX, double offZ) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.4)
      ..strokeWidth = 0.5;

    // 10ft major grid intervals
    const gridInterval = 10.0;
    final stepPx = gridInterval * scale;
    if (stepPx < 4) return;

    for (double x = offX; x <= offX + plotWidth * scale + 0.1; x += stepPx) {
      canvas.drawLine(Offset(x, offZ), Offset(x, offZ + plotDepth * scale), gridPaint);
    }
    for (double z = offZ; z <= offZ + plotDepth * scale + 0.1; z += stepPx) {
      canvas.drawLine(Offset(offX, z), Offset(offX + plotWidth * scale, z), gridPaint);
    }
  }

  void _drawPerimeterTrusses(Canvas canvas, double scale, Offset Function(double, double) toCanvas) {
    final trussWidth = math.max(6.0, 1.8 * scale);

    // North side: from (0, 0) to (width, 0)
    _drawSideTrussRuns(
      canvas: canvas,
      side: fourSides['north'],
      trussWidth: trussWidth,
      startPt: (dist) => toCanvas(dist, 0),
    );

    // East side: from (width, 0) to (width, depth)
    _drawSideTrussRuns(
      canvas: canvas,
      side: fourSides['east'],
      trussWidth: trussWidth,
      startPt: (dist) => toCanvas(plotWidth, dist),
    );

    // South side: from (0, depth) to (width, depth)
    _drawSideTrussRuns(
      canvas: canvas,
      side: fourSides['south'],
      trussWidth: trussWidth,
      startPt: (dist) => toCanvas(dist, plotDepth),
    );

    // West side: from (0, 0) to (0, depth)
    _drawSideTrussRuns(
      canvas: canvas,
      side: fourSides['west'],
      trussWidth: trussWidth,
      startPt: (dist) => toCanvas(0, dist),
    );
  }

  void _drawSideTrussRuns({
    required Canvas canvas,
    required BoundarySide? side,
    required double trussWidth,
    required Offset Function(double dist) startPt,
  }) {
    if (side == null) return;

    double accumulated = 0.0;
    for (final run in side.runs) {
      final p1 = startPt(accumulated);
      final p2 = startPt(accumulated + run.geometricSpan);
      accumulated += run.geometricSpan;

      _drawRealisticBoxTruss(canvas, p1, p2, trussWidth);
    }
  }

  void _drawCenterCrossTrusses(Canvas canvas, double scale, Offset Function(double, double) toCanvas) {
    if (centerRuns.isEmpty) return;
    final trussWidth = math.max(6.0, 1.8 * scale);

    for (final run in centerRuns) {
      final startPole = uniquePoles.firstWhere(
        (p) => p.id == run.startNodeId,
        orElse: () => _getFallbackCenterPole(),
      );
      final endPole = uniquePoles.firstWhere(
        (p) => p.id == run.endNodeId,
        orElse: () => _getFallbackCenterPole(),
      );

      final p1 = toCanvas(startPole.x, startPole.z);
      final p2 = toCanvas(endPole.x, endPole.z);

      _drawRealisticBoxTruss(canvas, p1, p2, trussWidth);
    }
  }

  BoundaryPole _getFallbackCenterPole() {
    return uniquePoles.firstWhere(
      (p) => p.connectedSideIds.contains('center'),
      orElse: () => BoundaryPole(
        id: 'fallback_center',
        x: plotWidth / 2.0,
        z: plotDepth / 2.0,
        isCorner: false,
        isSupportPole: true,
      ),
    );
  }

  void _drawRealisticBoxTruss(Canvas canvas, Offset p1, Offset p2, double width) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1.0) return;

    final ux = dx / len;
    final uy = dy / len;
    final nx = -uy * (width / 2);
    final ny = ux * (width / 2);

    // Outer truss chords (Silver aluminum look)
    final chordPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(p1.dx + nx, p1.dy + ny)
      ..lineTo(p2.dx + nx, p2.dy + ny)
      ..lineTo(p2.dx - nx, p2.dy - ny)
      ..lineTo(p1.dx - nx, p1.dy - ny)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawLine(Offset(p1.dx + nx, p1.dy + ny), Offset(p2.dx + nx, p2.dy + ny), chordPaint);
    canvas.drawLine(Offset(p1.dx - nx, p1.dy - ny), Offset(p2.dx - nx, p2.dy - ny), chordPaint);

    // Lattice X-bracing interior
    final latticePaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.7)
      ..strokeWidth = 1.0;

    final step = width * 1.5;
    final segments = (len / step).floor();
    for (int i = 0; i < segments; i++) {
      final t1 = (i * step) / len;
      final t2 = math.min(1.0, ((i + 1) * step) / len);

      final a1 = Offset(p1.dx + dx * t1 + nx, p1.dy + dy * t1 + ny);
      final a2 = Offset(p1.dx + dx * t2 + nx, p1.dy + dy * t2 + ny);
      final b1 = Offset(p1.dx + dx * t1 - nx, p1.dy + dy * t1 - ny);
      final b2 = Offset(p1.dx + dx * t2 - nx, p1.dy + dy * t2 - ny);

      canvas.drawLine(a1, b2, latticePaint);
      canvas.drawLine(b1, a2, latticePaint);
      canvas.drawLine(a2, b2, latticePaint);
    }
  }

  void _drawCenterLightTarget(Canvas canvas, double scale, Offset Function(double, double) toCanvas) {
    final centerPole = _getFallbackCenterPole();
    final center = toCanvas(centerPole.x, centerPole.z);

    // Ambient glow
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14.0, glowPaint);

    // Target circle
    final outerRingPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 8.0, outerRingPaint);

    // Inner bright center dot
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, centerDotPaint);
  }

  void _drawStructuralNodes(Canvas canvas, Offset Function(double, double) toCanvas) {
    for (final pole in uniquePoles) {
      final pt = toCanvas(pole.x, pole.z);
      final isSupportPole = pole.isSupportPole || pole.isCorner;

      if (isSupportPole) {
        // 🔴 Red Circle = Physical Support Pole (as per truss logic & corners)
        final haloPaint = Paint()
          ..color = const Color(0xFFEF4444).withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 8.0, haloPaint);

        final redDotPaint = Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 5.0, redDotPaint);

        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pt, 5.0, borderPaint);
      } else {
        // ⚪ White Circle = Structural Joint (connection point)
        final jointPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 4.0, jointPaint);

        final jointBorder = Paint()
          ..color = const Color(0xFF0F172A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pt, 4.0, jointBorder);
      }
    }
  }

  /// Architectural CAD dimension lines matching Stage Calculator exactly
  void _drawStageTypeDimensionLines(
    Canvas canvas,
    Rect plotRect,
    Offset Function(double, double) toCanvas,
    double scale,
  ) {
    void draw2DDimensionLine({
      required Offset pStart,
      required Offset pEnd,
      required String text,
      Color lineColor = const Color(0xFF00E5FF),
      Color badgeBg = const Color(0xEE0F172A),
      Color badgeBorder = const Color(0xFF00E5FF),
      Color textColor = Colors.white,
      double fontSize = 8.5,
    }) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(pStart, pEnd, linePaint);

      final dir = pEnd - pStart;
      final dist = dir.distance;
      if (dist > 3.0) {
        final norm = Offset(dir.dx / dist, dir.dy / dist);
        final perp = Offset(-norm.dy, norm.dx) * 3.5;

        // End-ticks
        canvas.drawLine(pStart - perp, pStart + perp, linePaint);
        canvas.drawLine(pEnd - perp, pEnd + perp, linePaint);

        // Arrows
        final arrowArm1 = (-norm + Offset(-norm.dy, norm.dx) * 0.5) * 4.5;
        final arrowArm2 = (-norm - Offset(-norm.dy, norm.dx) * 0.5) * 4.5;
        canvas.drawLine(pEnd, pEnd + arrowArm1, linePaint);
        canvas.drawLine(pEnd, pEnd + arrowArm2, linePaint);

        final startArm1 = (norm + Offset(-norm.dy, norm.dx) * 0.5) * 4.5;
        final startArm2 = (norm - Offset(-norm.dy, norm.dx) * 0.5) * 4.5;
        canvas.drawLine(pStart, pStart + startArm1, linePaint);
        canvas.drawLine(pStart, pStart + startArm2, linePaint);
      }

      final mid = Offset((pStart.dx + pEnd.dx) / 2.0, (pStart.dy + pEnd.dy) / 2.0);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp.width + 8.0;
      final badgeH = tp.height + 4.0;
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: mid, width: badgeW, height: badgeH),
        const Radius.circular(4),
      );

      canvas.drawRRect(badgeRect, Paint()..color = badgeBg);
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = badgeBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      tp.paint(canvas, Offset(mid.dx - tp.width / 2.0, mid.dy - tp.height / 2.0));
    }

    // 1. Overall Width Dimension Line along Top (y = -22.0 px above top edge)
    final topY = plotRect.top - 24.0;
    draw2DDimensionLine(
      pStart: Offset(plotRect.left, topY),
      pEnd: Offset(plotRect.right, topY),
      text: '${plotWidth.toInt()} ft',
      fontSize: 9.5,
    );

    // 2. Overall Depth Dimension Line along Right (x = +24.0 px right of right edge)
    final rightX = plotRect.right + 24.0;
    draw2DDimensionLine(
      pStart: Offset(rightX, plotRect.top),
      pEnd: Offset(rightX, plotRect.bottom),
      text: '${plotDepth.toInt()} ft',
      fontSize: 9.5,
    );

    // 3. Section Span Dimension Lines on North side runs
    final northSide = fourSides['north'];
    if (northSide != null && northSide.runs.isNotEmpty) {
      double acc = 0.0;
      for (final run in northSide.runs) {
        final startX = plotRect.left + acc * scale;
        final endX = plotRect.left + (acc + run.geometricSpan) * scale;
        acc += run.geometricSpan;

        final spanText = run.geometricSpan % 1 == 0
            ? '${run.geometricSpan.toInt()} ft'
            : '${run.geometricSpan.toStringAsFixed(1)} ft';

        final secY = plotRect.top + 14.0;
        final margin = math.min(4.0, (endX - startX) * 0.1);
        if ((endX - startX) > 4.0) {
          draw2DDimensionLine(
            pStart: Offset(startX + margin, secY),
            pEnd: Offset(endX - margin, secY),
            text: spanText,
            lineColor: const Color(0xFF38BDF8),
            badgeBg: const Color(0xDD0F172A),
            badgeBorder: const Color(0xFF38BDF8),
            textColor: const Color(0xFFE0F2FE),
            fontSize: 7.5,
          );
        }
      }
    }

    // 4. Section Span Dimension Lines on West side runs
    final westSide = fourSides['west'];
    if (westSide != null && westSide.runs.isNotEmpty) {
      double acc = 0.0;
      for (final run in westSide.runs) {
        final startZ = plotRect.top + acc * scale;
        final endZ = plotRect.top + (acc + run.geometricSpan) * scale;
        acc += run.geometricSpan;

        final spanText = run.geometricSpan % 1 == 0
            ? '${run.geometricSpan.toInt()} ft'
            : '${run.geometricSpan.toStringAsFixed(1)} ft';

        final secX = plotRect.left + 14.0;
        final margin = math.min(4.0, (endZ - startZ) * 0.1);
        if ((endZ - startZ) > 4.0) {
          draw2DDimensionLine(
            pStart: Offset(secX, startZ + margin),
            pEnd: Offset(secX, endZ - margin),
            text: spanText,
            lineColor: const Color(0xFF38BDF8),
            badgeBg: const Color(0xDD0F172A),
            badgeBorder: const Color(0xFF38BDF8),
            textColor: const Color(0xFFE0F2FE),
            fontSize: 7.5,
          );
        }
      }
    }
  }

  void _drawCompass(Canvas canvas, Size size) {
    const radius = 22.0;
    final center = Offset(size.width - 34.0, 34.0);

    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Compass arrows
    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius + 4)
      ..lineTo(center.dx - 4, center.dy)
      ..lineTo(center.dx + 4, center.dy)
      ..close();
    final northPaint = Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northPaint);

    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius - 4)
      ..lineTo(center.dx - 4, center.dy)
      ..lineTo(center.dx + 4, center.dy)
      ..close();
    final southPaint = Paint()..color = Colors.white70..style = PaintingStyle.fill;
    canvas.drawPath(southPath, southPaint);

    // Labels
    _drawCompassLabel(canvas, 'N', Offset(center.dx - 3, center.dy - radius + 6), const Color(0xFFEF4444));
    _drawCompassLabel(canvas, 'S', Offset(center.dx - 3, center.dy + radius - 14), Colors.white70);
    _drawCompassLabel(canvas, 'W', Offset(center.dx - radius + 5, center.dy - 4), Colors.white70);
    _drawCompassLabel(canvas, 'E', Offset(center.dx + radius - 10, center.dy - 4), Colors.white70);
  }

  void _drawCompassLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TrussBoundary2dPainter oldDelegate) {
    return oldDelegate.fourSides != fourSides ||
        oldDelegate.centerRuns != centerRuns ||
        oldDelegate.uniquePoles != uniquePoles ||
        oldDelegate.activeTool != activeTool ||
        oldDelegate.selectedSideId != selectedSideId ||
        oldDelegate.isCenterCrossActive != isCenterCrossActive;
  }
}

