import 'package:flutter/material.dart';
import '../../domain/models/flooring_calculation_result.dart';

class Flooring2DPainter extends CustomPainter {
  final FlooringCalculationResult result;

  Flooring2DPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    if (result.plotLength <= 0 || result.plotWidth <= 0) return;

    // Dark Engineering Canvas Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F172A),
    );

    const padding = 60.0;
    final maxL = result.coveredLength;
    final maxW = result.coveredWidth;

    final ratio = maxW / maxL;
    final canvasRatio = (size.width - 2 * padding) / (size.height - 2 * padding);

    double scale;
    if (ratio > canvasRatio) {
      scale = (size.width - 2 * padding) / maxW;
    } else {
      scale = (size.height - 2 * padding) / maxL;
    }

    final displayWidth = maxL * scale;
    final displayHeight = maxW * scale;

    final dx = (size.width - displayWidth) / 2;
    final dy = (size.height - displayHeight) / 2;

    canvas.save();
    canvas.translate(dx, dy);

    // Carpet Panel Fill & Seam Line Paints
    final carpetFillPaint = Paint()
      ..color = const Color(0xFFB91C1C) // Red event carpet fill
      ..style = PaintingStyle.fill;

    final carpetSeamPaint = Paint()
      ..color = const Color(0xFFF87171) // Thin seam border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final carpetInnerBorder = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Render individual carpet panels
    for (final carpet in result.carpetLayout) {
      final rect = Rect.fromLTWH(
        carpet.x * scale,
        carpet.z * scale,
        carpet.width * scale,
        carpet.depth * scale,
      );

      canvas.drawRect(rect, carpetFillPaint);
      canvas.drawRect(rect, carpetSeamPaint);
      canvas.drawRect(rect.deflate(1.0), carpetInnerBorder);

      // Render carpet ID if cell is large enough
      if (rect.width > 20 && rect.height > 14) {
        final textSpan = TextSpan(
          text: 'C${carpet.id + 1}',
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

    // Render Requested Plot Boundary Outline (Dashed/Cyan stroke)
    final plotRect = Rect.fromLTWH(
      0,
      0,
      result.plotLength * scale,
      result.plotWidth * scale,
    );

    final plotBoundaryPaint = Paint()
      ..color = const Color(0xFF38BDF8) // Cyan stroke for requested plot boundary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(plotRect, plotBoundaryPaint);

    // If actual coverage extends beyond plot boundary, draw Coverage Boundary (Amber stroke)
    if (result.coveredLength > result.plotLength || result.coveredWidth > result.plotWidth) {
      final coverageRect = Rect.fromLTWH(0, 0, displayWidth, displayHeight);
      final coverageBoundaryPaint = Paint()
        ..color = const Color(0xFFF59E0B) // Amber stroke for excess coverage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(coverageRect, coverageBoundaryPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Flooring2DPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
