import 'package:flutter/material.dart';
import '../../domain/models/stage_calculation_result.dart';

class Stage2DPainter extends CustomPainter {
  final StageCalculationResult result;

  Stage2DPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    if (result.stageLength <= 0 || result.stageWidth <= 0) return;

    // Dark Blueprint Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F19),
    );

    const padding = 60.0;
    final coveredLength = result.coveredLength;
    final coveredWidth = result.coveredWidth;

    final stageRatio = coveredWidth / coveredLength;
    final canvasRatio = (size.width - 2 * padding) / (size.height - 2 * padding);

    double scale;
    if (stageRatio > canvasRatio) {
      scale = (size.width - 2 * padding) / coveredWidth;
    } else {
      scale = (size.height - 2 * padding) / coveredLength;
    }

    final stageDisplayWidth = coveredLength * scale;
    final stageDisplayHeight = coveredWidth * scale;

    final dx = (size.width - stageDisplayWidth) / 2;
    final dy = (size.height - stageDisplayHeight) / 2;

    canvas.save();
    canvas.translate(dx, dy);

    // Draw requested stage outline (if different from covered area)
    if (result.stageLength != coveredLength || result.stageWidth != coveredWidth) {
      final reqPaint = Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, result.stageLength * scale, result.stageWidth * scale),
        reqPaint,
      );
    }

    // Table Fill & Border Paints
    final tableFillPaint = Paint()
      ..color = const Color(0xFF7F1D1D) // Deep red/crimson deck fill
      ..style = PaintingStyle.fill;

    final tableBorderPaint = Paint()
      ..color = const Color(0xFFF87171) // Light red/pinkish grid seam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final tableFramePaint = Paint()
      ..color = const Color(0xFF94A3B8) // Aluminium frame outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(
      color: Color(0xFFF8FAFC),
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    // Draw each stage table panel
    for (final table in result.tableLayoutPoints) {
      final rect = Rect.fromLTWH(
        table.x * scale,
        table.z * scale,
        table.width * scale,
        table.depth * scale,
      );

      // Fill panel deck
      canvas.drawRect(rect, tableFillPaint);
      // Seam / border
      canvas.drawRect(rect, tableBorderPaint);
      canvas.drawRect(rect.deflate(1.5), tableFramePaint);

      // Label table ID if enough space
      if (rect.width > 24 && rect.height > 16) {
        final textSpan = TextSpan(
          text: 'T${table.id + 1}',
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            rect.left + (rect.width - textPainter.width) / 2,
            rect.top + (rect.height - textPainter.height) / 2,
          ),
        );
      }
    }

    // Draw Front Stairs Visual (centered at the front width edge)
    final stairWidthWorld = result.orientedTableLength;
    final stairWidthCanvas = stairWidthWorld * scale;
    final stairXCanvas = (stageDisplayWidth - stairWidthCanvas) / 2;
    const stairStepCount = 3;
    const stepDepthCanvas = 8.0;

    final stairFillPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final stairBorderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 0; step < stairStepCount; step++) {
      final stepRect = Rect.fromLTWH(
        stairXCanvas + (step * 2.0),
        stageDisplayHeight + (step * stepDepthCanvas),
        stairWidthCanvas - (step * 4.0),
        stepDepthCanvas,
      );
      canvas.drawRect(stepRect, stairFillPaint);
      canvas.drawRect(stepRect, stairBorderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Stage2DPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
