import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/models/stage_calculation_result.dart';
import '../../domain/models/stage_table.dart';

class Stage3DPainter extends CustomPainter {
  final StageCalculationResult result;
  final double cameraAzimuth;
  final double cameraElevation;
  final double cameraZoom;

  Stage3DPainter({
    required this.result,
    this.cameraAzimuth = math.pi / 4,
    this.cameraElevation = math.pi / 5,
    this.cameraZoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || result.stageLength <= 0 || result.stageWidth <= 0) return;

    // Dark Blueprint Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F19),
    );

    final centerTarget = v64.Vector3(
      result.coveredLength / 2,
      result.stageHeight / 2,
      result.coveredWidth / 2,
    );

    final maxDim = math.max(math.max(result.coveredLength, result.coveredWidth), result.stageHeight * 3);
    final distance = math.max(maxDim * 2.2, 50.0) * cameraZoom;

    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      distance * cosElev * sinAzim,
      distance * sinElev,
      distance * cosElev * cosAzim,
    );

    final eyePosition = centerTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      centerTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = size.width / size.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      2000.0,
    );

    Offset? project(v64.Vector3 worldPoint) {
      final p = projectionMatrix * viewMatrix * v64.Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
      if (p.w == 0) return null;
      final ndc = v64.Vector3(p.x / p.w, p.y / p.w, p.z / p.w);
      if (ndc.z < -1 || ndc.z > 1) return null;

      return Offset(
        (ndc.x + 1.0) * 0.5 * size.width,
        (1.0 - ndc.y) * 0.5 * size.height,
      );
    }

    // Ground Grid & Floor Boundary
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final boundaryPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gP1 = project(v64.Vector3(0, 0, 0));
    final gP2 = project(v64.Vector3(result.coveredLength, 0, 0));
    final gP3 = project(v64.Vector3(result.coveredLength, 0, result.coveredWidth));
    final gP4 = project(v64.Vector3(0, 0, result.coveredWidth));

    if (gP1 != null && gP2 != null && gP3 != null && gP4 != null) {
      final groundPath = Path()
        ..moveTo(gP1.dx, gP1.dy)
        ..lineTo(gP2.dx, gP2.dy)
        ..lineTo(gP3.dx, gP3.dy)
        ..lineTo(gP4.dx, gP4.dy)
        ..close();
      canvas.drawPath(groundPath, boundaryPaint);
    }

    // Collect deduplicated leg support positions (X, Z) at table corners
    final Set<String> legKeys = {};
    final List<v64.Vector2> legPositions = [];

    for (final table in result.tableLayoutPoints) {
      final corners = [
        v64.Vector2(table.x, table.z),
        v64.Vector2(table.x + table.width, table.z),
        v64.Vector2(table.x + table.width, table.z + table.depth),
        v64.Vector2(table.x, table.z + table.depth),
      ];
      for (final c in corners) {
        final key = '${c.x.toStringAsFixed(2)},${c.y.toStringAsFixed(2)}';
        if (!legKeys.contains(key)) {
          legKeys.add(key);
          legPositions.add(c);
        }
      }
    }

    // Depth sort elements (legs & tables) back-to-front
    final cameraZDir = v64.Vector3(eyeOffset.x, eyeOffset.y, eyeOffset.z)..normalize();

    // 1. Draw Leg Supports (Poles + Base Plates + Bracings)
    final legPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final bracePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.5;

    final basePlatePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    legPositions.sort((a, b) {
      final vecA = v64.Vector3(a.x, 0, a.y) - eyePosition;
      final vecB = v64.Vector3(b.x, 0, b.y) - eyePosition;
      return vecB.dot(cameraZDir).compareTo(vecA.dot(cameraZDir));
    });

    for (final leg in legPositions) {
      final bPos = v64.Vector3(leg.x, 0, leg.y);
      final tPos = v64.Vector3(leg.x, result.stageHeight, leg.y);

      final pBase = project(bPos);
      final pTop = project(tPos);

      if (pBase != null && pTop != null) {
        // Base plate
        const pSize = 4.0;
        final platePath = Path()
          ..moveTo(pBase.dx - pSize, pBase.dy)
          ..lineTo(pBase.dx, pBase.dy - pSize * 0.5)
          ..lineTo(pBase.dx + pSize, pBase.dy)
          ..lineTo(pBase.dx, pBase.dy + pSize * 0.5)
          ..close();
        canvas.drawPath(platePath, basePlatePaint);

        // Leg pole
        canvas.drawLine(pBase, pTop, legPaint);
      }
    }

    // Draw Under-Deck Diagonal Bracing per table panel
    for (final table in result.tableLayoutPoints) {
      final p1 = project(v64.Vector3(table.x, 0, table.z));
      final p2 = project(v64.Vector3(table.x + table.width, result.stageHeight, table.z + table.depth));
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, bracePaint);
      }
    }

    // 2. Draw Stage Deck Tables (Sorted back-to-front)
    final sortedTables = List<StageTable>.from(result.tableLayoutPoints)
      ..sort((a, b) {
        final centerA = v64.Vector3(a.x + a.width / 2, result.stageHeight, a.z + a.depth / 2);
        final centerB = v64.Vector3(b.x + b.width / 2, result.stageHeight, b.z + b.depth / 2);
        final vecA = centerA - eyePosition;
        final vecB = centerB - eyePosition;
        return vecB.dot(cameraZDir).compareTo(vecA.dot(cameraZDir));
      });

    final deckTopPaint = Paint()
      ..color = const Color(0xFF991B1B) // Crimson deck top
      ..style = PaintingStyle.fill;

    final deckSeamPaint = Paint()
      ..color = const Color(0xFFEF4444) // Bright red deck seam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final frameRimPaint = Paint()
      ..color = const Color(0xFFCBD5E1) // Silver aluminium deck rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final h = result.stageHeight;

    for (final table in sortedTables) {
      final c0 = project(v64.Vector3(table.x, h, table.z));
      final c1 = project(v64.Vector3(table.x + table.width, h, table.z));
      final c2 = project(v64.Vector3(table.x + table.width, h, table.z + table.depth));
      final c3 = project(v64.Vector3(table.x, h, table.z + table.depth));

      if (c0 != null && c1 != null && c2 != null && c3 != null) {
        final deckPath = Path()
          ..moveTo(c0.dx, c0.dy)
          ..lineTo(c1.dx, c1.dy)
          ..lineTo(c2.dx, c2.dy)
          ..lineTo(c3.dx, c3.dy)
          ..close();

        canvas.drawPath(deckPath, deckTopPaint);
        canvas.drawPath(deckPath, deckSeamPaint);
        canvas.drawPath(deckPath, frameRimPaint);
      }
    }

    // 3. Draw Front Stairs (Centered along front stage width edge Z = coveredWidth)
    const int stepCount = 4;
    final stairWidth = result.orientedTableLength;
    final stairStartX = (result.coveredLength - stairWidth) / 2;
    final stairZ = result.coveredWidth;

    final stairTreadPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;

    final stairStringerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int step = 0; step < stepCount; step++) {
      final stepY = result.stageHeight * (stepCount - 1 - step) / stepCount;
      final stepZ = stairZ + (step * 0.7);

      final s0 = project(v64.Vector3(stairStartX, stepY, stepZ));
      final s1 = project(v64.Vector3(stairStartX + stairWidth, stepY, stepZ));
      final s2 = project(v64.Vector3(stairStartX + stairWidth, stepY, stepZ + 0.7));
      final s3 = project(v64.Vector3(stairStartX, stepY, stepZ + 0.7));

      if (s0 != null && s1 != null && s2 != null && s3 != null) {
        final stepPath = Path()
          ..moveTo(s0.dx, s0.dy)
          ..lineTo(s1.dx, s1.dy)
          ..lineTo(s2.dx, s2.dy)
          ..lineTo(s3.dx, s3.dy)
          ..close();

        canvas.drawPath(stepPath, stairTreadPaint);
        canvas.drawPath(stepPath, stairStringerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Stage3DPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.cameraAzimuth != cameraAzimuth ||
        oldDelegate.cameraElevation != cameraElevation ||
        oldDelegate.cameraZoom != cameraZoom;
  }
}
