import 'package:flutter/material.dart';
import '../../domain/models/pole_calculation_result.dart';

class Pole2DPainter extends CustomPainter {
  final PoleCalculationResult result;
  
  Pole2DPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    if (result.plotLength <= 0 || result.plotWidth <= 0) return;

    // Draw background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F19),
    );

    const padding = 60.0;
    final plotRatio = result.plotWidth / result.plotLength;
    final canvasRatio = (size.width - 2 * padding) / (size.height - 2 * padding);

    double scale;
    if (plotRatio > canvasRatio) {
      scale = (size.width - 2 * padding) / result.plotWidth;
    } else {
      scale = (size.height - 2 * padding) / result.plotLength;
    }

    final plotDisplayWidth = result.plotWidth * scale;
    final plotDisplayHeight = result.plotLength * scale;
    
    final dx = (size.width - plotDisplayWidth) / 2;
    final dy = (size.height - plotDisplayHeight) / 2;

    canvas.save();
    canvas.translate(dx, dy);

    // Boundary
    final boundaryPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, plotDisplayWidth, plotDisplayHeight), boundaryPaint);

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= result.grid.widthBays; i++) {
      double px = (i * result.poleSize).clamp(0.0, result.plotWidth) * scale;
      canvas.drawLine(Offset(px, 0), Offset(px, plotDisplayHeight), gridPaint);
    }
    for (int j = 1; j <= result.grid.lengthBays; j++) {
      double pz = (j * result.poleSize).clamp(0.0, result.plotLength) * scale;
      canvas.drawLine(Offset(0, pz), Offset(plotDisplayWidth, pz), gridPaint);
    }

    // Poles
    final polePaint = Paint()..color = const Color(0xFFCBD5E1); 
    
    for (final point in result.poleLayoutPoints) {
      final x = point.x * scale;
      final z = point.z * scale;
      canvas.drawCircle(Offset(x, z), 6.0, polePaint);
      canvas.drawCircle(Offset(x, z), 6.0, Paint()..color = const Color(0xFF000000)..style=PaintingStyle.stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Pole2DPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
