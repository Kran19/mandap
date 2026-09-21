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
      if (rect.width > 12 && rect.height > 10) {
        final textSpan = TextSpan(
          text: '${table.id + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
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

    // Render Requested Stage Limit Boundary Outline (Cyan stroke with glow)
    final stageReqRect = Rect.fromLTWH(
      0,
      0,
      result.stageLength * scale,
      result.stageWidth * scale,
    );

    // Cyan glow halo
    canvas.drawRect(
      stageReqRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
    // Crisp solid cyan outline
    canvas.drawRect(
      stageReqRect,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Excess along Length
    if (result.coveredLength > result.stageLength) {
      final excessL = result.coveredLength - result.stageLength;
      final excessRect = Rect.fromLTWH(
        result.stageLength * scale,
        0,
        excessL * scale,
        stageDisplayHeight,
      );

      // Warning wash and highlight over excess stage strip
      canvas.drawRect(
        excessRect,
        Paint()
          ..color = const Color(0x55F59E0B)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        excessRect,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Dividing cut-off line
      canvas.drawLine(
        Offset(result.stageLength * scale, 0),
        Offset(result.stageLength * scale, stageDisplayHeight),
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
    if (result.coveredWidth > result.stageWidth) {
      final excessW = result.coveredWidth - result.stageWidth;
      final excessWRect = Rect.fromLTWH(
        0,
        result.stageWidth * scale,
        stageDisplayWidth,
        excessW * scale,
      );

      canvas.drawRect(
        excessWRect,
        Paint()
          ..color = const Color(0x55F59E0B)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        excessWRect,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      canvas.drawLine(
        Offset(0, result.stageWidth * scale),
        Offset(stageDisplayWidth, result.stageWidth * scale),
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
      pEnd: Offset(result.stageLength * scale, -22.0),
      text: '${result.stageLength.toInt()} ft',
    );
    if (result.coveredLength > result.stageLength) {
      final exL = result.coveredLength - result.stageLength;
      final exLStr = exL % 1 == 0 ? exL.toStringAsFixed(0) : exL.toStringAsFixed(1);
      draw2DDimensionLine(
        pStart: Offset(result.stageLength * scale, -22.0),
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
      pEnd: Offset(-22.0, result.stageWidth * scale),
      text: '${result.stageWidth.toInt()} ft',
    );
    if (result.coveredWidth > result.stageWidth) {
      final exW = result.coveredWidth - result.stageWidth;
      final exWStr = exW % 1 == 0 ? exW.toStringAsFixed(0) : exW.toStringAsFixed(1);
      draw2DDimensionLine(
        pStart: Offset(-22.0, result.stageWidth * scale),
        pEnd: Offset(-22.0, result.coveredWidth * scale),
        text: '⚠ $exWStr ft Extra',
        lineColor: const Color(0xFFF59E0B),
        badgeBg: const Color(0xFF78350F),
        badgeBorder: const Color(0xFFFBBF24),
        textColor: const Color(0xFFFDE047),
      );
    }

    // Table Dimension Lines: Width on Table #2, Length on Table #18
    if (result.tableLayoutPoints.isNotEmpty) {
      final table2 = result.tableLayoutPoints.firstWhere(
        (t) => t.id == 1,
        orElse: () => result.tableLayoutPoints.first,
      );
      final table18 = result.tableLayoutPoints.firstWhere(
        (t) => t.id == 17,
        orElse: () => result.tableLayoutPoints.last,
      );

      final tLenStr = result.orientedTableLength % 1 == 0
          ? result.orientedTableLength.toInt().toString()
          : result.orientedTableLength.toStringAsFixed(1);
      final tWidStr = result.orientedTableWidth % 1 == 0
          ? result.orientedTableWidth.toInt().toString()
          : result.orientedTableWidth.toStringAsFixed(1);

      // 1. Table width arrow across Table #2 (horizontal across width axis)
      final t2X = (table2.x + table2.width * 0.35) * scale;
      draw2DDimensionLine(
        pStart: Offset(t2X, table2.z * scale),
        pEnd: Offset(t2X, (table2.z + table2.depth) * scale),
        text: '$tWidStr ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBg: const Color(0xFF0F172A),
        badgeBorder: const Color(0xFF00E5FF),
        textColor: const Color(0xFF00F0FF),
      );

      // 2. Table length arrow along Table #18 (vertical along length axis)
      final t18Z = (table18.z + table18.depth * 0.35) * scale;
      draw2DDimensionLine(
        pStart: Offset(table18.x * scale, t18Z),
        pEnd: Offset((table18.x + table18.width) * scale, t18Z),
        text: '$tLenStr ft',
        lineColor: const Color(0xFF00E5FF),
        badgeBg: const Color(0xFF0F172A),
        badgeBorder: const Color(0xFF00E5FF),
        textColor: const Color(0xFF00F0FF),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Stage2DPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
