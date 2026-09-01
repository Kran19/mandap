import 'package:flutter/material.dart';

import '../../application/editor_mode.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/node_id.dart';
import '../../domain/value_objects/mandap_calculation_result.dart';
import '../../domain/value_objects/pole_placement.dart';
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

  Mandap2DInteractivePainter({
    required this.layout,
    required this.result,
    required this.transform,
    required this.mode,
    this.selectedEdgeId,
    this.selectedNodeId,
    this.pendingEdgeSourceId,
    this.snapCursor,
  });

  // ── Paints ─────────────────────────────────────────────────────────────────

  static final _majorGridPaint = Paint()
    ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
    ..strokeWidth = 0.8;

  static final _minorGridPaint = Paint()
    ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.25)
    ..strokeWidth = 0.5;

  static final _edgePaint = Paint()
    ..color = const Color(0xFF1E293B)
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round;

  static final _selectedEdgePaint = Paint()
    ..color = const Color(0xFF2563EB)
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  static final _cornerNodePaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;

  static final _selectedNodePaint = Paint()
    ..color = const Color(0xFF2563EB)
    ..style = PaintingStyle.fill;

  static final _pendingSourcePaint = Paint()
    ..color = const Color(0xFF16A34A)
    ..style = PaintingStyle.fill;

  static final _generatedPolePaint = Paint()
    ..color = const Color(0xFFD97706)
    ..style = PaintingStyle.fill;

  static final _snapCursorPaint = Paint()
    ..color = const Color(0xFF2563EB).withValues(alpha: 0.5)
    ..style = PaintingStyle.fill;

  static final _nodeRingPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawEdges(canvas);
    _drawPoles(canvas);
    _drawNodes(canvas);
    if (snapCursor != null) _drawSnapCursor(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    // Visible world bounds
    final topLeft = transform.screenToWorld(Offset.zero);
    final bottomRight = transform.screenToWorld(
      Offset(size.width, size.height),
    );

    final startX = (topLeft.x / 5).floor() * 5.0 - 5;
    final endX = (bottomRight.x / 5).ceil() * 5.0 + 5;
    final startZ = (topLeft.z / 5).floor() * 5.0 - 5;
    final endZ = (bottomRight.z / 5).ceil() * 5.0 + 5;

    for (var wx = startX; wx <= endX; wx += 5.0) {
      final isMajor = (wx % 10).abs() < 0.01;
      final p1 = transform.worldToScreen(wx, startZ);
      final p2 = transform.worldToScreen(wx, endZ);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);
    }
    for (var wz = startZ; wz <= endZ; wz += 5.0) {
      final isMajor = (wz % 10).abs() < 0.01;
      final p1 = transform.worldToScreen(startX, wz);
      final p2 = transform.worldToScreen(endX, wz);
      canvas.drawLine(p1, p2, isMajor ? _majorGridPaint : _minorGridPaint);
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
