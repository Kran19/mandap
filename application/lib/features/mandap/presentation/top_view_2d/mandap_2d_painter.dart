import 'package:flutter/material.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/value_objects/mandap_calculation_result.dart';
import '../../domain/value_objects/pole_placement.dart';

/// 2D Canvas painter rendering [MandapLayout] and calculated poles top-down.
class Mandap2DPainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final EdgeId? selectedEdgeId;

  Mandap2DPainter({
    required this.layout,
    required this.result,
    this.selectedEdgeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.nodes.isEmpty) return;

    // Deterministic Coordinate Mapping: World X -> Canvas X, World Z -> Canvas Y
    // We use a fixed scale (e.g., 20 pixels per foot) so the coordinate system is stable.
    const double pixelsPerFoot = 20.0;
    
    // We want the origin (0,0) to be visible, so we can translate the canvas slightly
    // but InteractiveViewer will handle panning.
    Offset toCanvasOffset(double x, double z) {
      return Offset(x * pixelsPerFoot, z * pixelsPerFoot);
    }

    // 1. Draw Grid Background
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    const gridSize = 10.0; // 10 ft grid lines
    for (var x = -50.0; x <= 150.0; x += gridSize) {
      final p1 = toCanvasOffset(x, -50.0);
      final p2 = toCanvasOffset(x, 150.0);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (var z = -50.0; z <= 150.0; z += gridSize) {
      final p1 = toCanvasOffset(-50.0, z);
      final p2 = toCanvasOffset(150.0, z);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // 2. Draw Edges
    final edgePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final selectedEdgePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final p1 = toCanvasOffset(startNode.x, startNode.z);
        final p2 = toCanvasOffset(endNode.x, endNode.z);

        final isSelected = edge.id == selectedEdgeId;
        canvas.drawLine(p1, p2, isSelected ? selectedEdgePaint : edgePaint);

        // Draw Edge Label
        final len = layout.getEdgeLength(edge);
        final sol = result.edgeSolutions[edge.id];
        final pieceStr = sol != null && sol.exactFit
            ? ' (${sol.pieces.map((p) => p.length.ticks ~/ 2).join("+")})'
            : '';
        final labelText = '${len.toString()}$pieceStr';

        final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        _drawText(
          canvas,
          midPoint,
          labelText,
          Colors.black87,
          isBold: isSelected,
        );
      }
    }

    // 3. Draw Nodes (including poles)
    final cornerNodePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final controlNodePaint = Paint()
      ..color = const Color(0xFFD97706) // Amber for control points
      ..style = PaintingStyle.fill;

    for (final node in layout.nodes.values) {
      final center = toCanvasOffset(node.x, node.z);
      
      // Determine if it's a control point (e.g. Center Control for roof)
      // For now, if elevation is > 0 and it's a structural point, we mark it
      final isControl = node.elevation > 0;
      
      final radius = isControl ? 6.0 : 4.0;
      final paint = isControl ? controlNodePaint : cornerNodePaint;

      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      
      // Draw elevation label for structural points
      if (node.elevation > 0) {
        _drawText(
          canvas,
          center + const Offset(0, 12),
          'E:${node.elevation.toStringAsFixed(1)}',
          Colors.black54,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    Offset point,
    String text,
    Color color, {
    bool isBold = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        backgroundColor: Colors.white.withValues(alpha: 0.85),
      ),
    );

    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant Mandap2DPainter oldDelegate) =>
      layout != oldDelegate.layout ||
      result != oldDelegate.result ||
      selectedEdgeId != oldDelegate.selectedEdgeId;
}
