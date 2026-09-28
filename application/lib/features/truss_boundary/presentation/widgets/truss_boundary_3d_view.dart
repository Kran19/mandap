import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/boundary_pole.dart';
import '../../domain/entities/boundary_side.dart';
import '../../domain/entities/boundary_truss_run.dart';

/// Full-Screen Realistic 3D Festival & Mandap Environment matching Image 3.
/// Features sky gradient, lawn ground grid, 4-chord aluminum box truss, and vertical columns with steel base plates.
class TrussBoundary3dView extends StatefulWidget {
  final Map<String, BoundarySide> fourSides;
  final List<BoundaryTrussRun> centerRuns;
  final List<BoundaryPole> uniquePoles;
  final double plotWidth;
  final double plotDepth;
  final bool isCenterCrossActive;

  const TrussBoundary3dView({
    super.key,
    required this.fourSides,
    required this.centerRuns,
    required this.uniquePoles,
    required this.plotWidth,
    required this.plotDepth,
    this.isCenterCrossActive = false,
  });

  @override
  State<TrussBoundary3dView> createState() => _TrussBoundary3dViewState();
}

class _TrussBoundary3dViewState extends State<TrussBoundary3dView> {
  double _pitch = 0.52; // Vertical viewing angle (radians)
  double _yaw = -0.75; // Isometric rotation angle
  double _zoom = 1.05;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount == 1) {
            _yaw += details.focalPointDelta.dx * 0.008;
            _pitch = (_pitch - details.focalPointDelta.dy * 0.008).clamp(0.15, 1.4);
          } else if (details.pointerCount >= 2) {
            _zoom = (_zoom * details.scale).clamp(0.5, 3.0);
          }
        });
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7BB5E8), // Sky blue (matching Image 3)
              Color(0xFF99C9EE), // Soft horizon sky
              Color(0xFF88BD64), // Lawn horizon blend
              Color(0xFF6B9947), // Event lawn green
            ],
            stops: [0.0, 0.38, 0.42, 1.0],
          ),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _RealisticTruss3dPainter(
            fourSides: widget.fourSides,
            centerRuns: widget.centerRuns,
            uniquePoles: widget.uniquePoles,
            plotWidth: widget.plotWidth,
            plotDepth: widget.plotDepth,
            pitch: _pitch,
            yaw: _yaw,
            zoom: _zoom,
            isCenterCrossActive: widget.isCenterCrossActive,
          ),
        ),
      ),
    );
  }
}

class _RealisticTruss3dPainter extends CustomPainter {
  final Map<String, BoundarySide> fourSides;
  final List<BoundaryTrussRun> centerRuns;
  final List<BoundaryPole> uniquePoles;
  final double plotWidth;
  final double plotDepth;
  final double pitch;
  final double yaw;
  final double zoom;
  final bool isCenterCrossActive;

  static const double trussHeight = 18.0; // Height of truss structure in ft

  _RealisticTruss3dPainter({
    required this.fourSides,
    required this.centerRuns,
    required this.uniquePoles,
    required this.plotWidth,
    required this.plotDepth,
    required this.pitch,
    required this.yaw,
    required this.zoom,
    required this.isCenterCrossActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 40);
    final scale = (math.min(size.width, size.height) / (plotWidth * 1.5)) * zoom;

    // 3D Projection math: world (X, Y, Z) where Y is height up -> 2D screen (sx, sy)
    Offset project(double x, double y, double z) {
      final cx = x - plotWidth / 2;
      final cz = z - plotDepth / 2;
      final cy = y;

      // Rotate Yaw around Y axis
      final cosYaw = math.cos(yaw);
      final sinYaw = math.sin(yaw);
      final rx = cx * cosYaw - cz * sinYaw;
      final rz = cx * sinYaw + cz * cosYaw;

      // Rotate Pitch around X axis
      final cosPitch = math.cos(pitch);
      final sinPitch = math.sin(pitch);
      final ry = cy * cosPitch - rz * sinPitch;

      final sx = center.dx + rx * scale;
      final sy = center.dy - ry * scale;

      return Offset(sx, sy);
    }

    // 1. Draw Green Lawn Ground with Grid Lines (Matching Image 3)
    _drawLawnGround(canvas, project);

    // 2. Draw Subtle Stage & Backdrops in background
    _drawBackgroundStage(canvas, project);

    // 3. Draw Vertical Aluminum Box-Truss Support Columns with Steel Base Plates
    _drawSupportColumns(canvas, project);

    // 4. Draw Upper Box-Truss Perimeter Framework with Box-Chords
    _drawUpperTrusses(canvas, project);

    // 5. Draw Center Cross Upper Framework if active
    _drawCenterCross(canvas, project);

    // 6. Draw Stage-Type 3D Architectural CAD Dimension Lines & Badges
    _draw3DDimensionMarkings(canvas, project);
  }

  void _drawLawnGround(Canvas canvas, Offset Function(double, double, double) project) {
    const extraMargin = 40.0;
    final p0 = project(-extraMargin, 0, -extraMargin);
    final p1 = project(plotWidth + extraMargin, 0, -extraMargin);
    final p2 = project(plotWidth + extraMargin, 0, plotDepth + extraMargin);
    final p3 = project(-extraMargin, 0, plotDepth + extraMargin);

    final lawnPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    final lawnPaint = Paint()
      ..color = const Color(0xFF7FA850) // Crisp green grass
      ..style = PaintingStyle.fill;
    canvas.drawPath(lawnPath, lawnPaint);

    // Subtle lawn grid lines (matching Image 3)
    final gridPaint = Paint()
      ..color = const Color(0xFF6B9240).withOpacity(0.4)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x <= plotWidth; x += step) {
      canvas.drawLine(project(x, 0, 0), project(x, 0, plotDepth), gridPaint);
    }
    for (double z = 0; z <= plotDepth; z += step) {
      canvas.drawLine(project(0, 0, z), project(plotWidth, 0, z), gridPaint);
    }

    // Complete Electric Cyan Boundary Box on the Ground (EXACTLY like Stage)
    final b0 = project(0, 0.05, 0);
    final b1 = project(plotWidth, 0.05, 0);
    final b2 = project(plotWidth, 0.05, plotDepth);
    final b3 = project(0, 0.05, plotDepth);

    final boxPath = Path()
      ..moveTo(b0.dx, b0.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(b3.dx, b3.dy)
      ..close();

    // Luminous cyan glow halo
    canvas.drawPath(
      boxPath,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Crisp solid cyan boundary line completing the box
    canvas.drawPath(
      boxPath,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawBackgroundStage(Canvas canvas, Offset Function(double, double, double) project) {
    // Subtle backdrop fence at back (matching Image 3)
    final f0 = project(-10, 0, -10);
    final f1 = project(plotWidth + 10, 0, -10);
    final f0Top = project(-10, 6, -10);
    final f1Top = project(plotWidth + 10, 6, -10);

    final fencePath = Path()
      ..moveTo(f0.dx, f0.dy)
      ..lineTo(f1.dx, f1.dy)
      ..lineTo(f1Top.dx, f1Top.dy)
      ..lineTo(f0Top.dx, f0Top.dy)
      ..close();

    final fencePaint = Paint()
      ..color = const Color(0xFF2C3E50).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fencePath, fencePaint);
  }

  void _drawSupportColumns(Canvas canvas, Offset Function(double, double, double) project) {
    final supportPoles = uniquePoles.where((p) => p.isSupportPole || p.isCorner).toList();

    for (final pole in supportPoles) {
      final base = project(pole.x, 0, pole.z);
      final top = project(pole.x, trussHeight, pole.z);

      // Steel Base Plate with anchor bolts (matching Image 3)
      final platePaint = Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(base, 7.0, platePaint);

      final plateBorder = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(base, 7.0, plateBorder);

      // Vertical 4-chord aluminum box-truss column (thick silver structure)
      final colOuterPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(base, top, colOuterPaint);

      final colInnerPaint = Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 2.0;
      canvas.drawLine(base, top, colInnerPaint);

      // Column top connection cube / junction box (matching Image 3)
      final cubePaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(top, 5.0, cubePaint);

      final cubeBorder = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(top, 5.0, cubeBorder);
    }
  }

  void _drawUpperTrusses(Canvas canvas, Offset Function(double, double, double) project) {
    // North side: from (0, 0) to (plotWidth, 0)
    _drawSide3DTruss(canvas, project, fourSides['north'], (d) => Offset(d, 0));
    // East side: from (plotWidth, 0) to (plotWidth, plotDepth)
    _drawSide3DTruss(canvas, project, fourSides['east'], (d) => Offset(plotWidth, d));
    // South side: from (0, plotDepth) to (plotWidth, plotDepth)
    _drawSide3DTruss(canvas, project, fourSides['south'], (d) => Offset(d, plotDepth));
    // West side: from (0, 0) to (0, plotDepth)
    _drawSide3DTruss(canvas, project, fourSides['west'], (d) => Offset(0, d));
  }

  void _drawSide3DTruss(
    Canvas canvas,
    Offset Function(double, double, double) project,
    BoundarySide? side,
    Offset Function(double dist) getCoords,
  ) {
    if (side == null) return;

    double accumulated = 0.0;
    for (final run in side.runs) {
      final c1 = getCoords(accumulated);
      final c2 = getCoords(accumulated + run.geometricSpan);
      accumulated += run.geometricSpan;

      final p1 = project(c1.dx, trussHeight, c1.dy);
      final p2 = project(c2.dx, trussHeight, c2.dy);

      _drawRealistic3DTrussBeam(canvas, p1, p2);
    }
  }

  void _drawCenterCross(Canvas canvas, Offset Function(double, double, double) project) {
    if (centerRuns.isEmpty) return;

    final centerPole = _getFallbackCenterPole();
    final centerProjected = project(centerPole.x, trussHeight, centerPole.z);

    for (final run in centerRuns) {
      final startPole = uniquePoles.firstWhere(
        (p) => p.id == run.startNodeId,
        orElse: () => centerPole,
      );
      final endPole = uniquePoles.firstWhere(
        (p) => p.id == run.endNodeId,
        orElse: () => centerPole,
      );

      final p1 = project(startPole.x, trussHeight, startPole.z);
      final p2 = project(endPole.x, trussHeight, endPole.z);

      _drawRealistic3DTrussBeam(canvas, p1, p2);
    }

    // Glowing center light node at intersection in 3D
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerProjected, 9.0, glowPaint);

    final centerNodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerProjected, 5.0, centerNodePaint);
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

  void _drawRealistic3DTrussBeam(Canvas canvas, Offset p1, Offset p2) {
    // Outer Aluminum Box Chords
    final chordPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, chordPaint);

    // Inner Core / Lattice representation
    final corePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0;
    canvas.drawLine(p1, p2, corePaint);

    // Intermediate Joint Connector Splices
    final jointPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p1, 3.5, jointPaint);
    canvas.drawCircle(p2, 3.5, jointPaint);
  }

  /// 3D Architectural CAD Dimension Lines matching Stage 3D View exactly
  void _draw3DDimensionMarkings(Canvas canvas, Offset Function(double, double, double) project) {
    void draw3DDimensionLine({
      required double x1,
      required double y1,
      required double z1,
      required double x2,
      required double y2,
      required double z2,
      required String text,
      Color lineColor = const Color(0xFF00E5FF),
      Color badgeBg = const Color(0xEE0F172A),
      Color badgeBorder = const Color(0xFF00E5FF),
      Color textColor = Colors.white,
      double fontSize = 9.5,
    }) {
      final pStart = project(x1, y1, z1);
      final pEnd = project(x2, y2, z2);

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
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp.width + 12.0;
      final badgeH = tp.height + 6.0;
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

    // 1. Overall Width Dimension Line (along upper North frame)
    draw3DDimensionLine(
      x1: 0,
      y1: trussHeight + 2.5,
      z1: 0,
      x2: plotWidth,
      y2: trussHeight + 2.5,
      z2: 0,
      text: '${plotWidth.toInt()} ft',
    );

    // 2. Overall Depth Dimension Line (along upper East frame)
    draw3DDimensionLine(
      x1: plotWidth + 3.0,
      y1: trussHeight + 2.5,
      z1: 0,
      x2: plotWidth + 3.0,
      y2: trussHeight + 2.5,
      z2: plotDepth,
      text: '${plotDepth.toInt()} ft',
    );

    // 3. Section Span Dimension Badges along Perimeter Upper Truss Chords
    for (final entry in fourSides.entries) {
      final sideId = entry.key;
      final side = entry.value;
      double acc = 0.0;
      for (final run in side.runs) {
        final startPos = acc;
        final endPos = acc + run.geometricSpan;
        acc += run.geometricSpan;

        final spanText = run.geometricSpan % 1 == 0
            ? '${run.geometricSpan.toInt()} ft'
            : '${run.geometricSpan.toStringAsFixed(1)} ft';

        if (run.geometricSpan >= 1.0) {
          final margin = math.min(1.5, run.geometricSpan * 0.1);
          
          double x1 = 0.0, z1 = 0.0, x2 = 0.0, z2 = 0.0;
          switch (sideId) {
            case 'north':
              x1 = startPos + margin;
              z1 = 0;
              x2 = endPos - margin;
              z2 = 0;
              break;
            case 'east':
              x1 = plotWidth;
              z1 = startPos + margin;
              x2 = plotWidth;
              z2 = endPos - margin;
              break;
            case 'south':
              x1 = startPos + margin;
              z1 = plotDepth;
              x2 = endPos - margin;
              z2 = plotDepth;
              break;
            case 'west':
              x1 = 0;
              z1 = startPos + margin;
              x2 = 0;
              z2 = endPos - margin;
              break;
          }

          draw3DDimensionLine(
            x1: x1,
            y1: trussHeight + 0.8,
            z1: z1,
            x2: x2,
            y2: trussHeight + 0.8,
            z2: z2,
            text: spanText,
            lineColor: const Color(0xFF38BDF8),
            badgeBg: const Color(0xDD0F172A),
            badgeBorder: const Color(0xFF38BDF8),
            textColor: const Color(0xFFE0F2FE),
            fontSize: 8.0,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticTruss3dPainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.zoom != zoom ||
        oldDelegate.fourSides != fourSides ||
        oldDelegate.centerRuns != centerRuns ||
        oldDelegate.uniquePoles != uniquePoles ||
        oldDelegate.isCenterCrossActive != isCenterCrossActive;
  }
}
