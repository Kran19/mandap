import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/value_objects/pole_placement.dart';
import 'mandap_3d_controller.dart';
import 'math/beam_transform_calculator.dart';

/// CustomPainter executing the 3D rendering pipeline for Mandap truss structures.
class Mandap3DPainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final Mandap3DController controller;
  final EdgeId? selectedEdgeId;
  final NodeId? selectedNodeId;
  final NodeId? activeHandleNodeId;
  final double? dragPreviewLengthFeet;

  Mandap3DPainter({
    required this.layout,
    required this.result,
    required this.controller,
    this.selectedEdgeId,
    this.selectedNodeId,
    this.activeHandleNodeId,
    this.dragPreviewLengthFeet,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // View & Projection Matrix setup
    final centerTarget = controller.cameraCenterTarget;
    final cosElev = math.cos(controller.cameraElevation);
    final sinElev = math.sin(controller.cameraElevation);
    final cosAzim = math.cos(controller.cameraAzimuth);
    final sinAzim = math.sin(controller.cameraAzimuth);

    final eyeOffset = v64.Vector3(
      controller.cameraDistance * cosElev * sinAzim,
      controller.cameraDistance * sinElev,
      controller.cameraDistance * cosElev * cosAzim,
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
      1000.0,
    );

    final viewProj = projectionMatrix * viewMatrix;

    Offset? project(v64.Vector3 worldPoint) {
      final world4 = v64.Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
      final clip = viewProj * world4;
      if (clip.w <= 0.0) return null;
      final ndc = v64.Vector3(
        clip.x / clip.w,
        clip.y / clip.w,
        clip.z / clip.w,
      );
      final screenX = (ndc.x + 1.0) * 0.5 * size.width;
      final screenY = (1.0 - ndc.y) * 0.5 * size.height;
      return Offset(screenX, screenY);
    }

    // 1. Paint Ground Grid (10 ft grid intervals)
    _paintGroundGrid(canvas, project);

    // 2. Paint Vertical Support Poles (from calculationResult.poles)
    _paintPoles(canvas, project);

    // 3. Paint Top Beams (for ALL MandapEdges)
    _paintBeams(canvas, project);

    // 4. Paint Node Handles
    _paintHandles(canvas, project);

    // 5. Paint Dimension Overlay on Selected Beam
    _paintDimensionOverlay(canvas, size, project);
  }

  void _paintGroundGrid(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const gridSize = 100.0;
    const step = 10.0;

    for (double x = -gridSize; x <= gridSize; x += step) {
      final p1 = project(v64.Vector3(x, 0.0, -gridSize));
      final p2 = project(v64.Vector3(x, 0.0, gridSize));
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, gridPaint);
      }
    }

    for (double z = -gridSize; z <= gridSize; z += step) {
      final p1 = project(v64.Vector3(-gridSize, 0.0, z));
      final p2 = project(v64.Vector3(gridSize, 0.0, z));
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, gridPaint);
      }
    }

    // Origin marker
    final o = project(v64.Vector3(0, 0, 0));
    final ox = project(v64.Vector3(5, 0, 0));
    final oz = project(v64.Vector3(0, 0, 5));
    if (o != null && ox != null) {
      canvas.drawLine(
        o,
        ox,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2.0,
      );
    }
    if (o != null && oz != null) {
      canvas.drawLine(
        o,
        oz,
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0,
      );
    }
  }

  void _paintPoles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final defaultPolePaint = Paint()
      ..color =
          const Color(0xFFD97706) // Gold/Amber
      ..strokeWidth = 3.5;

    final intermediatePolePaint = Paint()
      ..color =
          const Color(0xFFF59E0B) // Amber accent for intermediate poles
      ..strokeWidth = 4.0;

    final height = controller.mandapHeight;

    for (final pole in result.poles) {
      final pBase = project(v64.Vector3(pole.x, 0.0, pole.z));
      final pTop = project(v64.Vector3(pole.x, height, pole.z));

      if (pBase != null && pTop != null) {
        final isIntermediate = pole.reason == PoleReason.generatedMaxSpan;
        final paint = isIntermediate ? intermediatePolePaint : defaultPolePaint;

        canvas.drawLine(pBase, pTop, paint);

        // Ground base plate dot
        canvas.drawCircle(pBase, isIntermediate ? 4.5 : 3.5, paint);
      }
    }
  }

  void _paintBeams(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final defaultBeamPaint = Paint()
      ..color =
          const Color(0xFF38BDF8) // Light blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final selectedBeamPaint = Paint()
      ..color =
          const Color(0xFF06B6D4) // Cyan highlight
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final height = controller.mandapHeight;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final p1 = project(v64.Vector3(startNode.x, height, startNode.z));
        final p2 = project(v64.Vector3(endNode.x, height, endNode.z));

        if (p1 != null && p2 != null) {
          final isSelected = edge.id == selectedEdgeId;
          final paint = isSelected ? selectedBeamPaint : defaultBeamPaint;

          canvas.drawLine(p1, p2, paint);

          if (isSelected) {
            // Draw outer glow outline for selected beam
            final glowPaint = Paint()
              ..color = const Color(0xFF22D3EE).withValues(alpha: 0.5)
              ..strokeWidth = 10.0
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(p1, p2, glowPaint);
            canvas.drawLine(p1, p2, paint);
          }
        }
      }
    }
  }

  void _paintHandles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final height = controller.mandapHeight;

    final startHandlePaint = Paint()..color = const Color(0xFF10B981); // Green
    final endHandlePaint = Paint()..color = const Color(0xFFEF4444); // Red
    final selectedNodePaint = Paint()
      ..color = const Color(0xFFF59E0B); // Yellow/Amber

    for (final node in layout.nodes.values) {
      final p = project(v64.Vector3(node.x, height, node.z));
      if (p != null) {
        if (selectedEdgeId != null) {
          final selectedEdge = layout.getEdge(selectedEdgeId!);
          if (selectedEdge != null) {
            if (node.id == selectedEdge.startNodeId) {
              canvas.drawCircle(p, 8.0, startHandlePaint);
              continue;
            } else if (node.id == selectedEdge.endNodeId) {
              canvas.drawCircle(p, 8.0, endHandlePaint);
              continue;
            }
          }
        }

        if (node.id == selectedNodeId || node.id == activeHandleNodeId) {
          canvas.drawCircle(p, 9.0, selectedNodePaint);
        } else {
          // Standard node dot
          canvas.drawCircle(p, 5.0, Paint()..color = Colors.white);
        }
      }
    }
  }

  void _paintDimensionOverlay(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
  ) {
    if (selectedEdgeId == null) return;
    final selectedEdge = layout.getEdge(selectedEdgeId!);
    if (selectedEdge == null) return;

    final startNode = layout.getNode(selectedEdge.startNodeId);
    final endNode = layout.getNode(selectedEdge.endNodeId);
    if (startNode == null || endNode == null) return;

    final transform = BeamTransformCalculator.calculate(
      startNode: startNode,
      endNode: endNode,
      height: controller.mandapHeight,
    );

    final midpointScreen = project(transform.center);
    if (midpointScreen == null) return;

    final displayLength = dragPreviewLengthFeet ?? transform.length;
    final labelText = '${displayLength.toStringAsFixed(1)} ft';

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textOffset = Offset(
      midpointScreen.dx - textPainter.width / 2.0,
      midpointScreen.dy - 24.0,
    );

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textOffset.dx - 6,
        textOffset.dy - 3,
        textPainter.width + 12,
        textPainter.height + 6,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF06B6D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant Mandap3DPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.result != result ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.activeHandleNodeId != activeHandleNodeId ||
        oldDelegate.dragPreviewLengthFeet != dragPreviewLengthFeet;
  }
}
