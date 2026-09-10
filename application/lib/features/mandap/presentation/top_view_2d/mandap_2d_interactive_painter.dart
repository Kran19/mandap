import 'package:flutter/material.dart';

import '../../application/editor_mode.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/mandap_zone.dart';
import '../../domain/entities/node_id.dart';
import '../../domain/value_objects/mandap_calculation_result.dart';
import '../../domain/value_objects/pole_placement.dart';
import '../../domain/value_objects/grid_settings.dart';
import '../viewport_transform.dart';

/// Full-featured interactive 2D painter for the Mandap layout editor.
///
/// Renders:
///   - 10 ft major / 5 ft minor grid
///   - Edges (with selection highlight, length label, truss decomposition)
///   - Corner / generated support poles
///   - Selection handles on selected node
///   - Pending edge source node highlight
///   - Snap cursor dot (when in addNode / move mode)
class Mandap2DInteractivePainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final ViewportTransform transform;
  final EditorMode mode;
  final EdgeId? selectedEdgeId;
  final NodeId? selectedNodeId;
  final NodeId? pendingEdgeSourceId;

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
    this.snapCursor,
    this.zoneDragStartWorld,
    this.zoneDragEndWorld,
    required this.gridSettings,
  });

  // ── Paints ─────────────────────────────────────────────────────────────────

  static final _lawnBackgroundPaint = Paint()
    ..color = const Color(0xFF0F2B1D) // Rich green event lawn
    ..style = PaintingStyle.fill;

  static final _majorGridPaint = Paint()
    ..color = const Color(0xFF52B788).withValues(alpha: 0.35)
    ..strokeWidth = 0.9;

  static final _minorGridPaint = Paint()
    ..color = const Color(0xFF52B788).withValues(alpha: 0.15)
    ..strokeWidth = 0.5;

  static final _edgePaint = Paint()
    ..color = const Color(0xFFFBBF24) // Bright Festive Gold
    ..strokeWidth = 5.0
    ..strokeCap = StrokeCap.round;

  static final _selectedEdgePaint = Paint()
    ..color = const Color(0xFF00F0FF) // Electric Neon Cyan
    ..strokeWidth = 7.0
    ..strokeCap = StrokeCap.round;

  static final _cornerNodePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final _selectedNodePaint = Paint()
    ..color = const Color(0xFF00F0FF)
    ..style = PaintingStyle.fill;

  static final _pendingSourcePaint = Paint()
    ..color = const Color(0xFF10B981)
    ..style = PaintingStyle.fill;

  static final _generatedPolePaint = Paint()
    ..color = const Color(0xFFF59E0B) // Amber
    ..style = PaintingStyle.fill;

  static final _snapCursorPaint = Paint()
    ..color = const Color(0xFF00F0FF).withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

  static final _nodeRingPaint = Paint()
    ..color = const Color(0xFFF59E0B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final _flooringPaint = Paint()
    ..color = const Color(0xFF7C3AED).withValues(alpha: 0.5) // Royal Purple
    ..style = PaintingStyle.fill;

  static final _flooringBorderPaint = Paint()
    ..color = const Color(0xFFA78BFA)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final _stagePaint = Paint()
    ..color = const Color(0xFFDC2626).withValues(alpha: 0.7) // Royal Red
    ..style = PaintingStyle.fill;

  static final _stageBorderPaint = Paint()
    ..color = const Color(0xFFFBBF24) // Gold trim
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final _activeZonePaint = Paint()
    ..color = const Color(0xFF00F0FF).withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;

  static final _activeZoneBorderPaint = Paint()
    ..color = const Color(0xFF00F0FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _lawnBackgroundPaint);
    _drawGrid(canvas, size);
    _drawZones(canvas);
    _drawEdges(canvas);
    _drawPoles(canvas);
    _drawNodes(canvas);
    if (snapCursor != null) _drawSnapCursor(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (!gridSettings.enabled) return;

    final topLeft = transform.screenToWorld(Offset.zero);
    final bottomRight = transform.screenToWorld(Offset(size.width, size.height));

    final major = gridSettings.majorSpacing;
    final minor = gridSettings.minorSpacing;
    final precision = gridSettings.displayPrecision;

    final startX = (topLeft.x / minor).floor() * minor - minor;
    final endX = (bottomRight.x / minor).ceil() * minor + minor;
    final startZ = (topLeft.z / minor).floor() * minor - minor;
    final endZ = (bottomRight.z / minor).ceil() * minor + minor;

    // Only draw sub grid if zoomed in enough (e.g. scale > 15)
    final drawSubGrid = transform.scale > 15.0;

    final numLinesX = ((endX - startX) / minor).abs();
    final numLinesZ = ((endZ - startZ) / minor).abs();

    if (numLinesX > 2000 || numLinesZ > 2000) {
      canvas.drawLine(transform.worldToScreen(0, startZ), transform.worldToScreen(0, endZ), _majorGridPaint);
      canvas.drawLine(transform.worldToScreen(startX, 0), transform.worldToScreen(endX, 0), _majorGridPaint);
      return;
    }

    for (var wx = startX; wx <= endX; wx += minor) {
      final isMajor = (wx % major).abs() < 0.001 || (wx % major - major).abs() < 0.001;
      if (!isMajor && !drawSubGrid) continue;
      
      final p1 = transform.worldToScreen(wx, startZ);
      final p2 = transform.worldToScreen(wx, endZ);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);

      // Coordinate Label for X (along the top edge)
      if (isMajor || (drawSubGrid && transform.scale > 40.0)) {
        final labelPos = transform.worldToScreen(wx, topLeft.z);
        if (labelPos.dx > 0 && labelPos.dx < size.width) {
          _drawLabel(canvas, Offset(labelPos.dx + 2, 10), wx.toStringAsFixed(precision), color: const Color(0xFF64748B), fontSize: 9);
        }
      }
    }

    for (var wz = startZ; wz <= endZ; wz += minor) {
      final isMajor = (wz % major).abs() < 0.001 || (wz % major - major).abs() < 0.001;
      if (!isMajor && !drawSubGrid) continue;

      final p1 = transform.worldToScreen(startX, wz);
      final p2 = transform.worldToScreen(endX, wz);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);

      // Coordinate Label for Z (along the left edge)
      if (isMajor || (drawSubGrid && transform.scale > 40.0)) {
        final labelPos = transform.worldToScreen(topLeft.x, wz);
        if (labelPos.dy > 0 && labelPos.dy < size.height) {
          _drawLabel(canvas, Offset(20, labelPos.dy + 2), wz.toStringAsFixed(precision), color: const Color(0xFF64748B), fontSize: 9);
        }
      }
    }
  }

  void _drawZones(Canvas canvas) {
    for (final zone in layout.zones) {
      final p1 = transform.worldToScreen(zone.x1, zone.y1);
      final p2 = transform.worldToScreen(zone.x2, zone.y2);
      final rect = Rect.fromPoints(p1, p2);

      if (zone.type == ZoneType.flooring) {
        canvas.drawRect(rect, _flooringPaint);
        canvas.drawRect(rect, _flooringBorderPaint);
      } else {
        canvas.drawRect(rect, _stagePaint);
        canvas.drawRect(rect, _stageBorderPaint);
      }
    }

    if (zoneDragStartWorld != null && zoneDragEndWorld != null) {
      final p1 = transform.worldToScreen(zoneDragStartWorld!.x, zoneDragStartWorld!.z);
      final p2 = transform.worldToScreen(zoneDragEndWorld!.x, zoneDragEndWorld!.z);
      final rect = Rect.fromPoints(p1, p2);
      canvas.drawRect(rect, _activeZonePaint);
      canvas.drawRect(rect, _activeZoneBorderPaint);
    }
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;

      final p1 = transform.worldToScreen(startNode.x, startNode.z);
      final p2 = transform.worldToScreen(endNode.x, endNode.z);
      final isSelected = edge.id == selectedEdgeId;

      canvas.drawLine(p1, p2, isSelected ? _selectedEdgePaint : _edgePaint);

      // Label: length + truss decomposition
      String lenStr;
      try {
        lenStr = layout.getEdgeLength(edge).toString();
      } on ArgumentError {
        final dist = edge.calculateGeometricDistanceFeet(startNode, endNode);
        lenStr = '${dist.toStringAsFixed(1)} ft';
      }
      final sol = result.edgeSolutions[edge.id];
      final pieceStr = sol != null && sol.exactFit
          ? ' (${sol.pieces.map((p) => '${p.length.ticks ~/ 2}ft').join('+')})'
          : '';
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      _drawLabel(canvas, midPoint, '$lenStr$pieceStr', isBold: isSelected);
    }
  }

  void _drawPoles(Canvas canvas) {
    for (final pole in result.poles) {
      final center = transform.worldToScreen(pole.x, pole.z);
      final isCorner = pole.reason == PoleReason.corner;
      final radius = isCorner ? 7.0 : 5.0;
      canvas.drawCircle(
        center,
        radius,
        isCorner ? _cornerNodePaint : _generatedPolePaint,
      );
      canvas.drawCircle(center, radius, _nodeRingPaint);
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in layout.nodes.values) {
      final center = transform.worldToScreen(node.x, node.z);
      final isSelected = node.id == selectedNodeId;
      final isPendingSource = node.id == pendingEdgeSourceId;

      if (node.type == NodeType.stage) {
        _drawAreaNode(canvas, node, center, const Color(0xFF334155).withValues(alpha: 0.8), isSelected);
        continue;
      } else if (node.type == NodeType.carpet) {
        _drawAreaNode(canvas, node, center, const Color(0xFF8B5CF6).withValues(alpha: 0.4), isSelected);
        continue;
      } else if (node.type == NodeType.pole) {
        _drawPoleNode(canvas, node, center, isSelected);
        continue;
      }

      if (node.isControlPoint) {
        // Distinct diamond glyph for center control point
        final diamondPaint = Paint()
          ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFFF59E0B)
          ..style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(center.dx, center.dy - 10)
          ..lineTo(center.dx + 10, center.dy)
          ..lineTo(center.dx, center.dy + 10)
          ..lineTo(center.dx - 10, center.dy)
          ..close();
        canvas.drawPath(path, diamondPaint);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        continue;
      }

      // If node has NO physical support, render as a hollow warning circle
      if (!node.hasPhysicalSupport) {
        final unsupportedPaint = Paint()
          ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFFEF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(center, isSelected ? 9.0 : 6.5, unsupportedPaint);
        canvas.drawCircle(
          center,
          isSelected ? 4.0 : 3.0,
          Paint()
            ..color = (isSelected ? const Color(0xFF00F0FF) : const Color(0xFFEF4444)).withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      Paint fill;
      double radius;
      if (isPendingSource) {
        fill = _pendingSourcePaint;
        radius = 10.0;
      } else if (isSelected) {
        fill = _selectedNodePaint;
        radius = 10.0;
      } else {
        fill = _cornerNodePaint;
        radius = 7.0;
      }

      // Draw selection ring
      if (isSelected || isPendingSource) {
        canvas.drawCircle(
          center,
          radius + 5,
          Paint()
            ..color =
                (isPendingSource
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB))
                    .withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, _nodeRingPaint);

      // Node ID label (small, above node)
      if (isSelected || isPendingSource) {
        _drawLabel(
          canvas,
          center - const Offset(0, 18),
          node.id.value,
          fontSize: 10,
          color: const Color(0xFF334155),
        );
      }
    }
  }

  void _drawAreaNode(Canvas canvas, MandapNode node, Offset center, Color color, bool isSelected) {
    final widthScreen = (node.width ?? 10.0) * transform.scale;
    final depthScreen = (node.depth ?? 10.0) * transform.scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(node.rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: widthScreen, height: depthScreen);
    
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    if (isSelected) {
      final borderPaint = Paint()..color = const Color(0xFF2563EB)..style = PaintingStyle.stroke..strokeWidth = 2;
      canvas.drawRect(rect, borderPaint);
    } else {
      final borderPaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1;
      canvas.drawRect(rect, borderPaint);
    }
    canvas.restore();
  }

  void _drawPoleNode(Canvas canvas, MandapNode node, Offset center, bool isSelected) {
    final widthScreen = (node.width ?? 1.0) * transform.scale;
    final depthScreen = (node.depth ?? 1.0) * transform.scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(node.rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: widthScreen, height: depthScreen);
    
    final paint = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill; // Amber for user pole
    canvas.drawRect(rect, paint);

    if (isSelected) {
      final borderPaint = Paint()..color = const Color(0xFF2563EB)..style = PaintingStyle.stroke..strokeWidth = 2;
      canvas.drawRect(rect, borderPaint);
    }
    canvas.restore();
  }

  void _drawSnapCursor(Canvas canvas) {
    final center = transform.worldToScreen(snapCursor!.x, snapCursor!.z);
    canvas.drawCircle(center, 5, _snapCursorPaint);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset point,
    String text, {
    bool isBold = false,
    double fontSize = 11,
    Color color = Colors.black87,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        backgroundColor: Colors.white.withValues(alpha: 0.85),
      ),
    );

    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant Mandap2DInteractivePainter oldDelegate) =>
      layout != oldDelegate.layout ||
      result != oldDelegate.result ||
      transform != oldDelegate.transform ||
      mode != oldDelegate.mode ||
      selectedEdgeId != oldDelegate.selectedEdgeId ||
      selectedNodeId != oldDelegate.selectedNodeId ||
      pendingEdgeSourceId != oldDelegate.pendingEdgeSourceId ||
      snapCursor != oldDelegate.snapCursor;
}
