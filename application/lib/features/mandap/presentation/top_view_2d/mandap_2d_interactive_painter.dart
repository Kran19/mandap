import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../application/editor_mode.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/mandap_zone.dart';
import '../../domain/entities/node_id.dart';
import '../../domain/value_objects/mandap_calculation_result.dart';
import '../../domain/value_objects/grid_settings.dart';
import '../../domain/services/truss_display_numbering_service.dart';
import '../../domain/services/truss_bay_detector.dart';
import '../../domain/entities/truss_bay.dart';
import '../viewport_transform.dart';

/// Full-featured interactive 2D engineering CAD painter for the Mandap layout editor.
/// Renders:
///   - Dark blueprint/engineering grid
///   - Top-right Compass Rose (N/E/S/W)
///   - Dual-chord aluminum box truss with X lattice bracing
///   - Red circle markers for Support Poles
///   - White circle markers for Joint / Connection
///   - Center Dot (Center Light)
///   - Interactive selection / drawing feedback
class Mandap2DInteractivePainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final ViewportTransform transform;
  final EditorMode mode;
  final EdgeId? selectedEdgeId;
  final NodeId? selectedNodeId;
  final NodeId? pendingEdgeSourceId;
  final TrussDisplayNumberingResult? displayNumbering;
  final List<TrussBay> bays;
  final String? selectedBayId;
  final double plotWidth;
  final double plotDepth;
  final bool showMarkings;

  /// Current snap position to render as a cursor dot (world coords), or null.
  final ({double x, double z})? snapCursor;
  
  final ({double x, double z})? zoneDragStartWorld;
  final ({double x, double z})? zoneDragEndWorld;

  final GridSettings gridSettings;

  Mandap2DInteractivePainter({
    required this.layout,
    required this.result,
    required this.transform,
    required this.mode,
    this.selectedEdgeId,
    this.selectedNodeId,
    this.pendingEdgeSourceId,
    this.displayNumbering,
    this.bays = const [],
    this.selectedBayId,
    this.snapCursor,
    this.zoneDragStartWorld,
    this.zoneDragEndWorld,
    required this.gridSettings,
    this.plotWidth = 100.0,
    this.plotDepth = 100.0,
    this.showMarkings = true,
  });

  // Paints
  static final _cadBackgroundPaint = Paint()
    ..color = const Color(0xFF0A1118) // Dark blueprint background
    ..style = PaintingStyle.fill;

  static final _majorGridPaint = Paint()
    ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.5)
    ..strokeWidth = 0.9;

  static final _minorGridPaint = Paint()
    ..color = const Color(0xFF1E293B).withValues(alpha: 0.35)
    ..strokeWidth = 0.5;

  static final _trussChordPaint = Paint()
    ..color = const Color(0xFFCBD5E1) // Silver aluminum
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final _trussLatticePaint = Paint()
    ..color = const Color(0xFF94A3B8).withValues(alpha: 0.85)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final _selectedTrussChordPaint = Paint()
    ..color = const Color(0xFF00E5FF) // Neon Cyan
    ..strokeWidth = 2.4
    ..style = PaintingStyle.stroke;

  static final _supportPolePaint = Paint()
    ..color = const Color(0xFFEF4444) // Vibrant Red
    ..style = PaintingStyle.fill;

  static final _supportPoleBorderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  static final _jointPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final _jointBorderPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final _centerDotGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  static final _centerDotPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.fill;

  static final _centerDotBorderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Blueprint Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _cadBackgroundPaint);

    // 2. Engineering Grid
    _drawGrid(canvas, size);

    // 3. Plot Boundary Box (Cyan Luminous Glow Matching Stage)
    _drawPlotBoundaryBox(canvas);

    // 4. Truss Edges (with dual chords & X lattice bracing)
    _drawTrussEdges(canvas);

    // 5. Nodes (Red Support Poles, White Joints, Center Dot)
    _drawNodes(canvas);

    // 6. Center Dot if not created yet
    _drawCenterDot(canvas);

    // 7. Stage-Type Architectural CAD Dimension Lines & Badges
    if (showMarkings) _drawStageTypeDimensionLines(canvas);

    // 8. Box Size Badges (00/00) in all created/detected bays
    if (showMarkings) _drawBayBoxSizeBadges(canvas);

    // 9. Snap cursor if active
    if (snapCursor != null) _drawSnapCursor(canvas);

    // 10. Compass Rose in Top-Right
    _drawCompassRose(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (!gridSettings.enabled) return;

    final topLeft = transform.screenToWorld(Offset.zero);
    final bottomRight = transform.screenToWorld(Offset(size.width, size.height));

    final major = gridSettings.majorSpacing > 0 ? gridSettings.majorSpacing : 10.0;
    final minor = gridSettings.minorSpacing > 0 ? gridSettings.minorSpacing : 2.0;

    final startX = (topLeft.x / minor).floor() * minor - minor;
    final endX = (bottomRight.x / minor).ceil() * minor + minor;
    final startZ = (topLeft.z / minor).floor() * minor - minor;
    final endZ = (bottomRight.z / minor).ceil() * minor + minor;

    final numLinesX = ((endX - startX) / minor).abs();
    final numLinesZ = ((endZ - startZ) / minor).abs();

    if (numLinesX > 2000 || numLinesZ > 2000) {
      canvas.drawLine(transform.worldToScreen(0, startZ), transform.worldToScreen(0, endZ), _majorGridPaint);
      canvas.drawLine(transform.worldToScreen(startX, 0), transform.worldToScreen(endX, 0), _majorGridPaint);
      return;
    }

    for (var wx = startX; wx <= endX; wx += minor) {
      final isMajor = (wx % major).abs() < 0.001 || (wx % major - major).abs() < 0.001;
      final p1 = transform.worldToScreen(wx, startZ);
      final p2 = transform.worldToScreen(wx, endZ);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);
    }

    for (var wz = startZ; wz <= endZ; wz += minor) {
      final isMajor = (wz % major).abs() < 0.001 || (wz % major - major).abs() < 0.001;
      final p1 = transform.worldToScreen(startX, wz);
      final p2 = transform.worldToScreen(endX, wz);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);
    }
  }

  void _drawTrussEdges(Canvas canvas) {
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;

      final p1 = transform.worldToScreen(startNode.x, startNode.z);
      final p2 = transform.worldToScreen(endNode.x, endNode.z);
      final isSelected = edge.id == selectedEdgeId;

      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length < 1.0) continue;

      final nx = -dy / length;
      final ny = dx / length;
      const halfWidth = 3.5; // 7px full visual width for box truss

      // Dual outer chords
      final chord1Start = Offset(p1.dx + nx * halfWidth, p1.dy + ny * halfWidth);
      final chord1End = Offset(p2.dx + nx * halfWidth, p2.dy + ny * halfWidth);
      final chord2Start = Offset(p1.dx - nx * halfWidth, p1.dy - ny * halfWidth);
      final chord2End = Offset(p2.dx - nx * halfWidth, p2.dy - ny * halfWidth);

      final chordPaint = isSelected ? _selectedTrussChordPaint : _trussChordPaint;
      canvas.drawLine(chord1Start, chord1End, chordPaint);
      canvas.drawLine(chord2Start, chord2End, chordPaint);

      // X Lattice cross bracing along truss length
      final segmentCount = (length / 14.0).floor().clamp(1, 150);
      for (int i = 0; i < segmentCount; i++) {
        final t0 = i / segmentCount;
        final t1 = (i + 1) / segmentCount;

        final a = Offset(p1.dx + dx * t0 + nx * halfWidth, p1.dy + dy * t0 + ny * halfWidth);
        final b = Offset(p1.dx + dx * t0 - nx * halfWidth, p1.dy + dy * t0 - ny * halfWidth);
        final c = Offset(p1.dx + dx * t1 + nx * halfWidth, p1.dy + dy * t1 + ny * halfWidth);
        final d = Offset(p1.dx + dx * t1 - nx * halfWidth, p1.dy + dy * t1 - ny * halfWidth);

        // Cross braces
        canvas.drawLine(a, d, _trussLatticePaint);
        canvas.drawLine(b, c, _trussLatticePaint);
        // Cross strut
        canvas.drawLine(c, d, _trussLatticePaint);
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    final selectedEdge = selectedEdgeId != null ? layout.edges[selectedEdgeId] : null;

    final selectedPolePaint = Paint()
      ..color = const Color(0xFF00E5FF) // Electric Blue/Cyan when selected
      ..style = PaintingStyle.fill;

    final selectedPoleGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    for (final node in layout.nodes.values) {
      if (node.isControlPoint) continue; // Handled separately in _drawCenterDot

      final center = transform.worldToScreen(node.x, node.z);
      final isSelected = node.id == selectedNodeId ||
          node.id == pendingEdgeSourceId ||
          (selectedEdge != null && (selectedEdge.startNodeId == node.id || selectedEdge.endNodeId == node.id));
      final isSupportPole = node.support == NodeSupport.pole || node.type == NodeType.corner || node.type == NodeType.pole;

      if (isSupportPole) {
        if (isSelected) {
          // Selected: Turn red dot into vibrant blue with glowing halo
          canvas.drawCircle(center, 12.0, selectedPoleGlowPaint);
          canvas.drawCircle(center, 8.0, selectedPolePaint);
          canvas.drawCircle(center, 8.0, _supportPoleBorderPaint);
        } else {
          // Unselected: Red circular marker with white border
          canvas.drawCircle(center, 7.5, _supportPolePaint);
          canvas.drawCircle(center, 7.5, _supportPoleBorderPaint);
        }
      } else {
        if (isSelected) {
          canvas.drawCircle(center, 10.0, selectedPoleGlowPaint);
          canvas.drawCircle(center, 6.5, selectedPolePaint);
          canvas.drawCircle(center, 6.5, _supportPoleBorderPaint);
        } else {
          // White circular joint marker with dark border
          canvas.drawCircle(center, 5.5, _jointPaint);
          canvas.drawCircle(center, 5.5, _jointBorderPaint);
        }
      }
    }
  }

  void _drawCenterDot(Canvas canvas) {
    // Check if center node already exists in layout
    MandapNode? centerNode;
    for (final node in layout.nodes.values) {
      if (node.isControlPoint || node.type == NodeType.controlPoint || node.id.value.contains('center')) {
        centerNode = node;
        break;
      }
    }
    final cX = centerNode?.x ?? (plotWidth / 2.0);
    final cZ = centerNode?.z ?? (plotDepth / 2.0);
    final centerScreen = transform.worldToScreen(cX, cZ);

    // Glowing cyan/white center dot
    canvas.drawCircle(centerScreen, 12.0, _centerDotGlowPaint);
    canvas.drawCircle(centerScreen, 6.0, _centerDotPaint);
    canvas.drawCircle(centerScreen, 6.0, _centerDotBorderPaint);
  }

  void _drawSnapCursor(Canvas canvas) {
    final center = transform.worldToScreen(snapCursor!.x, snapCursor!.z);
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, paint);
  }

  void _drawCompassRose(Canvas canvas, Size size) {
    const double margin = 20.0;
    const double radius = 22.0;
    final center = Offset(size.width - margin - radius, margin + radius);

    // Compass circle background
    final bgPaint = Paint()
      ..color = const Color(0xFF0F263B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // North arrow needle (Red)
    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius + 4)
      ..lineTo(center.dx - 3.5, center.dy)
      ..lineTo(center.dx + 3.5, center.dy)
      ..close();
    canvas.drawPath(northPath, Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill);

    // South arrow needle (White)
    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius - 4)
      ..lineTo(center.dx - 3.5, center.dy)
      ..lineTo(center.dx + 3.5, center.dy)
      ..close();
    canvas.drawPath(southPath, Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.fill);

    // Letters: N, E, S, W
    _drawCompassLetter(canvas, Offset(center.dx, center.dy - radius + 8), 'N', const Color(0xFFEF4444));
    _drawCompassLetter(canvas, Offset(center.dx + radius - 7, center.dy), 'E', Colors.white70);
    _drawCompassLetter(canvas, Offset(center.dx, center.dy + radius - 8), 'S', Colors.white70);
    _drawCompassLetter(canvas, Offset(center.dx - radius + 7, center.dy), 'W', Colors.white70);
  }

  void _drawCompassLetter(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawPlotBoundaryBox(Canvas canvas) {
    // Plot boundary box blue outline removed per user request
  }

  void _drawStageTypeDimensionLines(Canvas canvas) {
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

    final p0 = transform.worldToScreen(0, 0);
    final p1 = transform.worldToScreen(plotWidth, plotDepth);
    final plotRect = Rect.fromPoints(p0, p1);

    final extPaint = Paint()
      ..color = const Color(0x6600E5FF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 1. Overall Width Dimension Line along Top (with 50px gap + extension lines)
    final topY = plotRect.top - 50.0;
    canvas.drawLine(Offset(plotRect.left, plotRect.top - 8.0), Offset(plotRect.left, topY - 6.0), extPaint);
    canvas.drawLine(Offset(plotRect.right, plotRect.top - 8.0), Offset(plotRect.right, topY - 6.0), extPaint);

    draw2DDimensionLine(
      pStart: Offset(plotRect.left, topY),
      pEnd: Offset(plotRect.right, topY),
      text: '${plotWidth.toInt()} ft',
      fontSize: 9.5,
    );

    // 2. Overall Depth Dimension Line along Right (with 50px gap + extension lines)
    final rightX = plotRect.right + 50.0;
    canvas.drawLine(Offset(plotRect.right + 8.0, plotRect.top), Offset(rightX + 6.0, plotRect.top), extPaint);
    canvas.drawLine(Offset(plotRect.right + 8.0, plotRect.bottom), Offset(rightX + 6.0, plotRect.bottom), extPaint);

    draw2DDimensionLine(
      pStart: Offset(rightX, plotRect.top),
      pEnd: Offset(rightX, plotRect.bottom),
      text: '${plotDepth.toInt()} ft',
      fontSize: 9.5,
    );

    // 3. Size badges placed directly on each truss member
    for (final edge in layout.edges.values) {
      final sn = layout.getNode(edge.startNodeId);
      final en = layout.getNode(edge.endNodeId);
      if (sn == null || en == null) continue;

      final pStart = transform.worldToScreen(sn.x, sn.z);
      final pEnd = transform.worldToScreen(en.x, en.z);
      final dx = en.x - sn.x;
      final dz = en.z - sn.z;
      final spanFeet = math.sqrt(dx * dx + dz * dz);
      final screenDist = (pEnd - pStart).distance;

      if (screenDist > 20.0 && spanFeet > 1.0) {
        final isWhole = spanFeet % 1 == 0;
        final valStr = isWhole ? '${spanFeet.round()}' : spanFeet.toStringAsFixed(1);
        final text = '$valStr ft';
        final mid = (pStart + pEnd) / 2.0;

        final isSelected = edge.id == selectedEdgeId;
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeW = math.max(tp.width + 8.0, 20.0);
        final badgeH = math.max(tp.height + 4.0, 16.0);
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: mid, width: badgeW, height: badgeH),
          const Radius.circular(5),
        );

        canvas.drawRRect(badgeRect, Paint()..color = const Color(0xEE0F172A));
        canvas.drawRRect(
          badgeRect,
          Paint()
            ..color = isSelected ? const Color(0xFF00E5FF) : const Color(0xFF334155)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 1.4 : 0.8,
        );
        tp.paint(canvas, Offset(mid.dx - tp.width / 2.0, mid.dy - tp.height / 2.0));
      }
    }
  }

  void _drawBayBoxSizeBadges(Canvas canvas) {
    if (!showMarkings) return;
    final effectiveBays = bays.isNotEmpty ? bays : const TrussBayDetector().detectBays(layout);
    for (final bay in effectiveBays) {
      final centerScreen = transform.worldToScreen(bay.centerX, bay.centerZ);
      final isSelected = bay.id == selectedBayId;

      final w = bay.widthFt % 1 == 0 ? bay.widthFt.toInt().toString() : bay.widthFt.toStringAsFixed(1);
      final l = bay.lengthFt % 1 == 0 ? bay.lengthFt.toInt().toString() : bay.lengthFt.toStringAsFixed(1);
      final text = '$w × $l ft';

      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFFF1F5F9),
            fontSize: isSelected ? 10.5 : 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp.width + 10.0;
      final badgeH = tp.height + 6.0;
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centerScreen, width: badgeW, height: badgeH),
        const Radius.circular(5),
      );

      if (isSelected) {
        // Selected cyan glow
        canvas.drawRRect(
          badgeRect.inflate(2.0),
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFA0F172A));
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = isSelected ? const Color(0xFF00E5FF) : const Color(0xFF475569)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 1.0,
      );
      tp.paint(canvas, Offset(centerScreen.dx - tp.width / 2.0, centerScreen.dy - tp.height / 2.0));
    }
  }

  @override
  bool shouldRepaint(covariant Mandap2DInteractivePainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.transform != transform ||
        oldDelegate.mode != mode ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.selectedBayId != selectedBayId ||
        oldDelegate.bays != bays ||
        oldDelegate.snapCursor != snapCursor ||
        oldDelegate.showMarkings != showMarkings;
  }
}
