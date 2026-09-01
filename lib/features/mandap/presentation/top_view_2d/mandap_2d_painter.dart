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

    // Determine spatial bounding box of nodes
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minZ = double.infinity;
    var maxZ = -double.infinity;

    for (final node in layout.nodes.values) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.z < minZ) minZ = node.z;
      if (node.z > maxZ) maxZ = node.z;
    }

    final layoutWidth = (maxX - minX).clamp(1.0, 1000.0);
    final layoutHeight = (maxZ - minZ).clamp(1.0, 1000.0);

    const padding = 40.0;
    final scaleX = (size.width - padding * 2) / layoutWidth;
    final scaleZ = (size.height - padding * 2) / layoutHeight;
    final scale = scaleX < scaleZ ? scaleX : scaleZ;

    final offsetX = (size.width - layoutWidth * scale) / 2 - minX * scale;
    final offsetZ = (size.height - layoutHeight * scale) / 2 - minZ * scale;

    Offset toCanvasOffset(double x, double z) {
      return Offset(x * scale + offsetX, z * scale + offsetZ);
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

    // 3. Draw Support Poles
    final cornerPolePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final generatedPolePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    for (final pole in result.poles) {
      final center = toCanvasOffset(pole.x, pole.z);
      final radius = pole.reason == PoleReason.corner ? 7.0 : 5.0;
      final paint = pole.reason == PoleReason.corner
          ? cornerPolePaint
          : generatedPolePaint;

      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
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
