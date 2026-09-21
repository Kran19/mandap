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

    // Render individual carpet panels
    for (final carpet in result.carpetLayout) {
      final rect = Rect.fromLTWH(
        carpet.x * scale,
        carpet.z * scale,
        carpet.width * scale,
        carpet.depth * scale,
      );

      const Color fill = Color(0xFFB91C1C); // Crimson Red
      const Color stroke = Color(0xFF7F1D1D);

      canvas.drawRect(
        rect,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Render carpet number if cell is large enough
      if (rect.width > 12 && rect.height > 10) {
        final textSpan = TextSpan(
          text: '${carpet.id + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.0,
            fontWeight: FontWeight.bold,
          ),
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

    // Render Requested Plot Boundary Outline (Cyan stroke with glow)
    final plotRect = Rect.fromLTWH(
      0,
      0,
      result.plotLength * scale,
      result.plotWidth * scale,
    );

    // Cyan glow halo
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // Core cyan line
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // If actual coverage extends beyond plot boundary, highlight excess area and draw dividing line
    if (result.coveredLength > result.plotLength || result.coveredWidth > result.plotWidth) {
      final coverageRect = Rect.fromLTWH(0, 0, displayWidth, displayHeight);
      final coverageBoundaryPaint = Paint()
        ..color = const Color(0xFFF59E0B) // Amber stroke for excess coverage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(coverageRect, coverageBoundaryPaint);

      // Excess along Length
      if (result.coveredLength > result.plotLength) {
        final excessL = result.coveredLength - result.plotLength;
        final excessRect = Rect.fromLTWH(
          result.plotLength * scale,
          0,
          excessL * scale,
          displayHeight,
        );

        // Warning wash over excess carpet strip
        canvas.drawRect(
          excessRect,
          Paint()
            ..color = const Color(0x35F59E0B)
            ..style = PaintingStyle.fill,
        );

        // Dividing cut-off line
        canvas.drawLine(
          Offset(result.plotLength * scale, 0),
          Offset(result.plotLength * scale, displayHeight),
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..strokeWidth = 2.8,
        );

        // Label
        final excessLStr = excessL % 1 == 0 ? excessL.toStringAsFixed(0) : excessL.toStringAsFixed(1);
        final labelSpan = TextSpan(
          text: '⚠ +$excessLStr ft Extra',
          style: const TextStyle(
            color: Color(0xFFFDE047),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
        tp.paint(
          canvas,
          Offset(
            excessRect.left + (excessRect.width - tp.width) / 2.0,
            excessRect.top + (excessRect.height - tp.height) / 2.0,
          ),
        );
      }

      // Excess along Width
      if (result.coveredWidth > result.plotWidth) {
        final excessW = result.coveredWidth - result.plotWidth;
        final excessWRect = Rect.fromLTWH(
          0,
          result.plotWidth * scale,
          displayWidth,
          excessW * scale,
        );

        canvas.drawRect(
          excessWRect,
          Paint()
            ..color = const Color(0x35F59E0B)
            ..style = PaintingStyle.fill,
        );

        canvas.drawLine(
          Offset(0, result.plotWidth * scale),
          Offset(displayWidth, result.plotWidth * scale),
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..strokeWidth = 2.8,
        );

        final excessWStr = excessW % 1 == 0 ? excessW.toStringAsFixed(0) : excessW.toStringAsFixed(1);
        final labelSpan = TextSpan(
          text: '⚠ +$excessWStr ft Extra',
          style: const TextStyle(
            color: Color(0xFFFDE047),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
        tp.paint(
          canvas,
          Offset(
            excessWRect.left + (excessWRect.width - tp.width) / 2.0,
            excessWRect.top + (excessWRect.height - tp.height) / 2.0,
          ),
        );
      }
    }

    // 2D Architectural CAD Dimension Lines
    void draw2DDimensionLine({
      required Offset pStart,
      required Offset pEnd,
      required String text,
      Color lineColor = const Color(0xFF00E5FF),
      Color badgeBg = const Color(0xEE0F172A),
      Color badgeBorder = const Color(0xFF00E5FF),
      Color textColor = Colors.white,
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

        canvas.drawLine(pStart - perp, pStart + perp, linePaint);
        canvas.drawLine(pEnd - perp, pEnd + perp, linePaint);
      }

      final mid = Offset((pStart.dx + pEnd.dx) / 2.0, (pStart.dy + pEnd.dy) / 2.0);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp.width + 10.0;
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

    // Length dimension along the top (y = -22.0)
    draw2DDimensionLine(
      pStart: const Offset(0, -22.0),
      pEnd: Offset(result.plotLength * scale, -22.0),
      text: '${result.plotLength.toInt()} ft',
    );
    if (result.coveredLength > result.plotLength) {
      final exL = result.coveredLength - result.plotLength;
      final exLStr = exL % 1 == 0 ? exL.toStringAsFixed(0) : exL.toStringAsFixed(1);
      draw2DDimensionLine(
        pStart: Offset(result.plotLength * scale, -22.0),
        pEnd: Offset(result.coveredLength * scale, -22.0),
        text: '⚠ $exLStr ft Extra',
        lineColor: const Color(0xFFF59E0B),
        badgeBg: const Color(0xFF78350F),
        badgeBorder: const Color(0xFFFBBF24),
        textColor: const Color(0xFFFDE047),
      );
    }

    // Width dimension along the left (x = -22.0)
    draw2DDimensionLine(
      pStart: const Offset(-22.0, 0),
      pEnd: Offset(-22.0, result.plotWidth * scale),
      text: '${result.plotWidth.toInt()} ft',
    );
    if (result.coveredWidth > result.plotWidth) {
      final exW = result.coveredWidth - result.plotWidth;
      final exWStr = exW % 1 == 0 ? exW.toStringAsFixed(0) : exW.toStringAsFixed(1);
      draw2DDimensionLine(
        pStart: Offset(-22.0, result.plotWidth * scale),
        pEnd: Offset(-22.0, result.coveredWidth * scale),
        text: '⚠ $exWStr ft Extra',
        lineColor: const Color(0xFFF59E0B),
        badgeBg: const Color(0xFF78350F),
        badgeBorder: const Color(0xFFFBBF24),
        textColor: const Color(0xFFFDE047),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Flooring2DPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
