import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../features/mandap/domain/entities/edge_id.dart';
import '../../features/mandap/domain/entities/mandap_layout.dart';
import '../../features/mandap/domain/entities/node_id.dart';
import '../../features/mandap/domain/value_objects/mandap_calculation_result.dart';
import '../../features/mandap/domain/value_objects/pole_placement.dart';

/// 3D Scene Primitive type for z-depth sorting.
enum PrimitiveType { gridLine, beam, pole, handle }

class RenderPrimitive {
  final PrimitiveType type;
  final double depth; // Distance from camera for z-sorting
  final VoidCallback drawCallback;

  RenderPrimitive({
    required this.type,
    required this.depth,
    required this.drawCallback,
  });
}

/// 3D Interactive Canvas Painter rendering Mandap layout primitives, camera perspective, lighting, and handles.
class Mandap3DCanvasPainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final EdgeId? selectedEdgeId;
  final NodeId? activeHandleNodeId;
  final double cameraAzimuth;
  final double cameraElevation;
  final double cameraDistance;
  final double? dragPreviewLengthFeet;
  final bool isPerformanceTestMode;
  final int performanceObjectCount;

  Mandap3DCanvasPainter({
    required this.layout,
    required this.result,
    this.selectedEdgeId,
    this.activeHandleNodeId,
    required this.cameraAzimuth,
    required this.cameraElevation,
    required this.cameraDistance,
    this.dragPreviewLengthFeet,
    this.isPerformanceTestMode = false,
    this.performanceObjectCount = 100,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Setup Camera Eye, Target, Matrices
    final centerTarget = v64.Vector3(20.0, 5.0, 15.0);

    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      cameraDistance * cosElev * sinAzim,
      cameraDistance * sinElev,
      cameraDistance * cosElev * cosAzim,
    );

    final eyePosition = centerTarget + eyeOffset;
    final upVector = v64.Vector3(0.0, 1.0, 0.0);

    final viewMatrix = v64.makeViewMatrix(eyePosition, centerTarget, upVector);
    final aspect = size.width / size.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      1000.0,
    );

    final viewProjectionMatrix = projectionMatrix * viewMatrix;

    Offset project(v64.Vector3 worldPos) {
      final vec = v64.Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0);
      final clip = viewProjectionMatrix.transformed(vec);

      if (clip.w <= 0.0) return const Offset(-9999, -9999);

      final ndcX = clip.x / clip.w;
      final ndcY = clip.y / clip.w;

      final screenX = (ndcX + 1.0) * size.width / 2.0;
      final screenY = (1.0 - ndcY) * size.height / 2.0;

      return Offset(screenX, screenY);
    }

    double getDepth(v64.Vector3 worldPos) => (worldPos - eyePosition).length2;

    final primitives = <RenderPrimitive>[];

    // 2. Add Ground Grid Primitives
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;

    for (var x = -20.0; x <= 60.0; x += 10.0) {
      final p1 = v64.Vector3(x, 0.0, -20.0);
      final p2 = v64.Vector3(x, 0.0, 50.0);
      final mid = (p1 + p2) * 0.5;

      primitives.add(
        RenderPrimitive(
          type: PrimitiveType.gridLine,
          depth: getDepth(mid),
          drawCallback: () {
            final sp1 = project(p1);
            final sp2 = project(p2);
            if (sp1.dx > -9000 && sp2.dx > -9000) {
              canvas.drawLine(sp1, sp2, gridPaint);
            }
          },
        ),
      );
    }

    for (var z = -20.0; z <= 50.0; z += 10.0) {
      final p1 = v64.Vector3(-20.0, 0.0, z);
      final p2 = v64.Vector3(60.0, 0.0, z);
      final mid = (p1 + p2) * 0.5;

      primitives.add(
        RenderPrimitive(
          type: PrimitiveType.gridLine,
          depth: getDepth(mid),
          drawCallback: () {
            final sp1 = project(p1);
            final sp2 = project(p2);
            if (sp1.dx > -9000 && sp2.dx > -9000) {
              canvas.drawLine(sp1, sp2, gridPaint);
            }
          },
        ),
      );
    }

    // 3. Add Vertical Support Poles (Poles from Y = 0 to Y = 10 ft)
    const mandapHeight = 10.0;

    final cornerPolePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final generatedPolePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (final pole in result.poles) {
      final b1 = v64.Vector3(pole.x, 0.0, pole.z);
      final b2 = v64.Vector3(pole.x, mandapHeight, pole.z);
      final mid = (b1 + b2) * 0.5;

      primitives.add(
        RenderPrimitive(
          type: PrimitiveType.pole,
          depth: getDepth(mid),
          drawCallback: () {
            final sb1 = project(b1);
            final sb2 = project(b2);
            if (sb1.dx > -9000 && sb2.dx > -9000) {
              final paint = pole.reason == PoleReason.corner
                  ? cornerPolePaint
                  : generatedPolePaint;
              canvas.drawLine(sb1, sb2, paint);
            }
          },
        ),
      );
    }

    // 4. Add Top Horizontal Beams (Beams at Y = 10 ft)
    final normalBeamPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final selectedBeamPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final p1 = v64.Vector3(startNode.x, mandapHeight, startNode.z);
        final p2 = v64.Vector3(endNode.x, mandapHeight, endNode.z);
        final mid = (p1 + p2) * 0.5;

        final isSelected = edge.id == selectedEdgeId;

        primitives.add(
          RenderPrimitive(
            type: PrimitiveType.beam,
            depth: getDepth(mid),
            drawCallback: () {
              final sp1 = project(p1);
              final sp2 = project(p2);

              if (sp1.dx > -9000 && sp2.dx > -9000) {
                canvas.drawLine(
                  sp1,
                  sp2,
                  isSelected ? selectedBeamPaint : normalBeamPaint,
                );

                // 5. Draw Endpoint Handles if Edge is Selected
                if (isSelected) {
                  _drawHandleSphere(
                    canvas,
                    sp1,
                    isStart: true,
                    node: startNode,
                  );
                  _drawHandleSphere(canvas, sp2, isStart: false, node: endNode);

                  // Dimension Text Overlay
                  final len = layout.getEdgeLength(edge);
                  final displayText = dragPreviewLengthFeet != null
                      ? '${dragPreviewLengthFeet!.toStringAsFixed(1)} ft'
                      : len.toString();

                  final labelPos = Offset(
                    (sp1.dx + sp2.dx) / 2,
                    (sp1.dy + sp2.dy) / 2 - 18,
                  );
                  _drawTextOverlay(
                    canvas,
                    labelPos,
                    displayText,
                    isHighlight: true,
                  );
                }
              }
            },
          ),
        );
      }
    }

    // 6. Performance Test Mode: Spawn extra benchmark primitives if enabled
    if (isPerformanceTestMode) {
      final perfPaint = Paint()
        ..color = Colors.indigo.withValues(alpha: 0.5)
        ..strokeWidth = 2.0;

      final count = performanceObjectCount.clamp(10, 1000);
      final side = math.sqrt(count).ceil();

      for (var i = 0; i < count; i++) {
        final gx = (i % side) * 5.0 - 30.0;
        final gz = (i ~/ side) * 5.0 - 30.0;

        final b1 = v64.Vector3(gx, 0.0, gz);
        final b2 = v64.Vector3(gx, 8.0, gz);
        final mid = (b1 + b2) * 0.5;

        primitives.add(
          RenderPrimitive(
            type: PrimitiveType.pole,
            depth: getDepth(mid),
            drawCallback: () {
              final sb1 = project(b1);
              final sb2 = project(b2);
              if (sb1.dx > -9000 && sb2.dx > -9000) {
                canvas.drawLine(sb1, sb2, perfPaint);
              }
            },
          ),
        );
      }
    }

    // Sort primitives back-to-front (descending depth) for correct Z-ordering
    primitives.sort((a, b) => b.depth.compareTo(a.depth));

    // Execute primitive draw calls
    for (final prim in primitives) {
      prim.drawCallback();
    }
  }

  void _drawHandleSphere(
    Canvas canvas,
    Offset pos, {
    required bool isStart,
    required dynamic node,
  }) {
    final handlePaint = Paint()
      ..color = isStart ? const Color(0xFF10B981) : const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(pos, 9.0, handlePaint);
    canvas.drawCircle(pos, 9.0, borderPaint);
  }

  void _drawTextOverlay(
    Canvas canvas,
    Offset point,
    String text, {
    bool isHighlight = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: isHighlight ? const Color(0xFF1E293B) : Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: isHighlight
            ? const Color(0xFFFEF08A)
            : Colors.white.withValues(alpha: 0.9),
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
  bool shouldRepaint(covariant Mandap3DCanvasPainter oldDelegate) => true;
}
