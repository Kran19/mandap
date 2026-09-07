import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/entities/mandap_zone.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/value_objects/pole_placement.dart';
import '../../../application/coordinate_transform.dart';
import 'mandap_3d_controller.dart';
import 'math/beam_transform_calculator.dart';

/// CustomPainter executing the 3D rendering pipeline for Mandap truss structures.
class Mandap3DPainter extends CustomPainter {
  final MandapLayout layout;
  final MandapCalculationResult result;
  final Mandap3DController controller;
  final EdgeId? selectedEdgeId;
  final NodeId? selectedNodeId;
  final NodeId? pendingEdgeSourceId;
  final NodeId? activeHandleNodeId;
  final double? dragPreviewLengthFeet;

  Mandap3DPainter({
    required this.layout,
    required this.result,
    required this.controller,
    this.selectedEdgeId,
    this.selectedNodeId,
    this.pendingEdgeSourceId,
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

    Offset? project(v64.Vector3 worldPoint) {
      return CoordinateTransform.worldToScreen3D(
        worldPoint: worldPoint,
        viewportSize: size,
        viewMatrix: viewMatrix,
        projectionMatrix: projectionMatrix,
      );
    }

    // 1. Paint Ground Grid (10 ft grid intervals)
    _paintGroundGrid(canvas, project);

    // 1.25 Paint Custom Zones (Flooring, Stage)
    _paintZones(canvas, project);

    // 1.5 Paint Polymorphic Nodes (Stage, Carpet, user Poles)
    _paintPolymorphicNodes(canvas, project);

    // 2. Paint Vertical Support Poles (from calculationResult.poles)
    _paintPoles(canvas, project);

    // 3. Paint Top Beams (for ALL MandapEdges)
    _paintBeams(canvas, project);

    // 4. Paint Node Handles
    _paintHandles(canvas, project);

    // 5. Paint Dimension Overlays for all beams
    _paintDimensionOverlays(canvas, size, project);
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

  void _paintZones(Canvas canvas, Offset? Function(v64.Vector3) project) {
    for (final zone in layout.zones) {
      final left = math.min(zone.x1, zone.x2);
      final right = math.max(zone.x1, zone.x2);
      final top = math.min(zone.y1, zone.y2);
      final bottom = math.max(zone.y1, zone.y2);

      final h = zone.type == ZoneType.flooring ? 0.01 : 2.0; // 2ft stage

      final color = zone.type == ZoneType.stage 
          ? const Color(0xFF334155).withValues(alpha: 0.8) 
          : const Color(0xFF8B5CF6).withValues(alpha: 0.4);

      final paint = Paint()..color = color..style = PaintingStyle.fill;
      final strokePaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.0;

      // Subdivide into 5x5 ft chunks to prevent the entire floor from disappearing 
      // when a single corner is behind the camera near-plane.
      const double tileSize = 5.0;
      for (double x = left; x < right; x += tileSize) {
        for (double z = top; z < bottom; z += tileSize) {
          final xEnd = math.min(x + tileSize, right);
          final zEnd = math.min(z + tileSize, bottom);

          final worldCornersBase = [
            v64.Vector3(x, 0, z),
            v64.Vector3(xEnd, 0, z),
            v64.Vector3(xEnd, 0, zEnd),
            v64.Vector3(x, 0, zEnd),
          ];

          final worldCornersTop = worldCornersBase.map((c) => v64.Vector3(c.x, c.y + h, c.z)).toList();

          _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: zone.type == ZoneType.stage);
        }
      }
    }
  }

  void _paintPolymorphicNodes(Canvas canvas, Offset? Function(v64.Vector3) project) {
    for (final node in layout.nodes.values) {
      if (node.type == NodeType.corner || node.type == NodeType.junction || node.type == NodeType.openEnd || node.type == NodeType.generatedSupport) {
        continue;
      }

      final w = node.width ?? 10.0;
      final d = node.depth ?? 10.0;
      
      // Carpet visual height is a tiny epsilon for z-fighting, regardless of physical thickness.
      // Stage uses physical height. Pole uses editor controller height.
      final h = node.type == NodeType.carpet 
          ? 0.01 
          : node.height ?? (node.type == NodeType.pole ? controller.mandapHeight : 0.0);
          
      // Elevation (base position Y)
      final elev = node.elevation;
      final rot = node.rotation;

      final halfW = w / 2;
      final halfD = d / 2;

      // 4 corners on local XZ plane
      final localCorners = [
        v64.Vector3(-halfW, 0, -halfD),
        v64.Vector3(halfW, 0, -halfD),
        v64.Vector3(halfW, 0, halfD),
        v64.Vector3(-halfW, 0, halfD),
      ];

      final cosR = math.cos(rot);
      final sinR = math.sin(rot);

      // Transform corners to world
      final worldCornersBase = localCorners.map((c) {
        final rx = c.x * cosR - c.z * sinR;
        final rz = c.x * sinR + c.z * cosR;
        return v64.Vector3(node.x + rx, elev, node.z + rz);
      }).toList();

      final worldCornersTop = worldCornersBase.map((c) => v64.Vector3(c.x, c.y + h, c.z)).toList();

      final isSelected = node.id == selectedNodeId;

      if (node.type == NodeType.stage || node.type == NodeType.carpet) {
        final color = node.type == NodeType.stage 
            ? const Color(0xFF334155).withValues(alpha: 0.8) 
            : const Color(0xFF8B5CF6).withValues(alpha: 0.4);

        final paint = Paint()..color = color..style = PaintingStyle.fill;
        final strokePaint = Paint()..color = (isSelected ? const Color(0xFF2563EB) : Colors.white24)..style = PaintingStyle.stroke..strokeWidth = isSelected ? 2.0 : 1.0;

        _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: node.type == NodeType.stage);
      } else if (node.type == NodeType.pole) {
        final paint = Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.6)..style = PaintingStyle.fill;
        final strokePaint = Paint()..color = (isSelected ? const Color(0xFF2563EB) : const Color(0xFFD97706))..style = PaintingStyle.stroke..strokeWidth = isSelected ? 2.0 : 1.0;
        _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: true);
      }
    }
  }

  void _draw3DBox(Canvas canvas, Offset? Function(v64.Vector3) project, List<v64.Vector3> base, List<v64.Vector3> top, Paint fill, Paint stroke, {bool drawSides = true}) {
    final projBase = base.map(project).toList();
    final projTop = top.map(project).toList();

    if (projBase.any((p) => p == null) || projTop.any((p) => p == null)) return;

    final pb = projBase.cast<Offset>();
    final pt = projTop.cast<Offset>();

    void drawPoly(List<Offset> pts) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    // Top face
    drawPoly(pt);
    
    // Base face
    drawPoly(pb);

    if (drawSides) {
      // 4 side faces
      for (int i = 0; i < 4; i++) {
        final next = (i + 1) % 4;
        drawPoly([pb[i], pb[next], pt[next], pt[i]]);
      }
    }
  }

  void _paintPoles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final chordPaint = Paint()
      ..color = const Color(0xFF94A3B8) // Silver/Aluminum
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final webPaint = Paint()
      ..color = const Color(0xFF64748B) // Slightly darker for inner webbing
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final height = controller.mandapHeight;
    const halfW = 0.5; // 1 ft total width

    for (final pole in result.poles) {
      // 4 corners of the box truss
      final offsets = [
        v64.Vector3(-halfW, 0, -halfW),
        v64.Vector3(halfW, 0, -halfW),
        v64.Vector3(halfW, 0, halfW),
        v64.Vector3(-halfW, 0, halfW),
      ];

      final baseWorld = v64.Vector3(pole.x, 0.0, pole.z);
      
      // Draw zigzag webbing on each of the 4 faces
      for (int i = 0; i < 4; i++) {
        final offA = offsets[i];
        final offB = offsets[(i + 1) % 4];

        // Draw diagonals every 2 feet
        for (double y = 0; y < height; y += 2.0) {
          final p1 = project(baseWorld + offA + v64.Vector3(0, y, 0));
          final p2 = project(baseWorld + offB + v64.Vector3(0, math.min(y + 2.0, height), 0));
          if (p1 != null && p2 != null) canvas.drawLine(p1, p2, webPaint);
          
          final p3 = project(baseWorld + offB + v64.Vector3(0, y, 0));
          final p4 = project(baseWorld + offA + v64.Vector3(0, math.min(y + 2.0, height), 0));
          if (p3 != null && p4 != null) canvas.drawLine(p3, p4, webPaint);
        }
      }

      // Draw the 4 vertical chords
      for (final off in offsets) {
        final pBase = project(baseWorld + off);
        final pTop = project(baseWorld + off + v64.Vector3(0, height, 0));
        if (pBase != null && pTop != null) {
          canvas.drawLine(pBase, pTop, chordPaint);
        }
      }
    }
  }

  void _paintBeams(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final chordPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // Bright silver
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final selectedChordPaint = Paint()
      ..color = const Color(0xFF06B6D4) // Cyan highlight
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final webPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final height = controller.mandapHeight;
    const halfW = 0.5;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final isSelected = edge.id == selectedEdgeId;
        final cPaint = isSelected ? selectedChordPaint : chordPaint;
        final wPaint = isSelected ? selectedChordPaint : webPaint;

        final start = v64.Vector3(startNode.x, height, startNode.z);
        final end = v64.Vector3(endNode.x, height, endNode.z);
        
        final dir = (end - start)..normalize();
        final up = v64.Vector3(0, 1, 0);
        final right = dir.cross(up)..normalize();

        // 4 corners relative to centerline
        final offsets = [
          (right * -halfW) + (up * -halfW),
          (right * halfW) + (up * -halfW),
          (right * halfW) + (up * halfW),
          (right * -halfW) + (up * halfW),
        ];

        final length = start.distanceTo(end);

        // Webbing
        for (int i = 0; i < 4; i++) {
          final offA = offsets[i];
          final offB = offsets[(i + 1) % 4];

          for (double d = 0; d < length; d += 2.0) {
            final segStart = math.min(d, length);
            final segEnd = math.min(d + 2.0, length);
            
            final p1 = project(start + (dir * segStart) + offA);
            final p2 = project(start + (dir * segEnd) + offB);
            if (p1 != null && p2 != null) canvas.drawLine(p1, p2, wPaint);
            
            final p3 = project(start + (dir * segStart) + offB);
            final p4 = project(start + (dir * segEnd) + offA);
            if (p3 != null && p4 != null) canvas.drawLine(p3, p4, wPaint);
          }
        }

        // 4 chords
        for (final off in offsets) {
          final p1 = project(start + off);
          final p2 = project(end + off);
          if (p1 != null && p2 != null) {
            if (isSelected) {
              canvas.drawLine(p1, p2, Paint()..color = const Color(0xFF22D3EE).withValues(alpha: 0.5)..strokeWidth = 12.0..strokeCap = StrokeCap.round);
            }
            canvas.drawLine(p1, p2, cPaint);
          }
        }
      }
    }
  }

  void _paintHandles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final height = controller.mandapHeight;

    final startHandlePaint = Paint()..color = const Color(0xFF10B981); // Green
    final endHandlePaint = Paint()..color = const Color(0xFFEF4444); // Red
    final selectedNodePaint = Paint()..color = const Color(0xFFF59E0B); // Yellow/Amber
    final pendingSourcePaint = Paint()..color = const Color(0xFF22C55E); // Bright Green

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

        if (node.id == pendingEdgeSourceId) {
          canvas.drawCircle(p, 9.0, pendingSourcePaint);
        } else if (node.id == selectedNodeId || node.id == activeHandleNodeId) {
          canvas.drawCircle(p, 9.0, selectedNodePaint);
        } else {
          // Standard node dot
          canvas.drawCircle(p, 5.0, Paint()..color = Colors.white);
        }
      }
    }
  }

  void _paintDimensionOverlays(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
  ) {
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;

      final isSelected = edge.id == selectedEdgeId;

      final transform = BeamTransformCalculator.calculate(
        startNode: startNode,
        endNode: endNode,
        height: controller.mandapHeight,
      );

      final midpointScreen = project(transform.center);
      if (midpointScreen == null) continue;

      final displayLength = (isSelected && dragPreviewLengthFeet != null)
          ? dragPreviewLengthFeet!
          : transform.length;
      final labelText = '${displayLength.toStringAsFixed(1)} ft';

      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: isSelected ? 12 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        midpointScreen.dx - textPainter.width / 2.0,
        midpointScreen.dy - (isSelected ? 24.0 : 16.0),
      );

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textOffset.dx - 4,
          textOffset.dy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        bgRect,
        Paint()..color = const Color(0xFF0F172A).withValues(alpha: isSelected ? 0.85 : 0.6),
      );

      if (isSelected) {
        canvas.drawRRect(
          bgRect,
          Paint()
            ..color = const Color(0xFF06B6D4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      } else {
        canvas.drawRRect(
          bgRect,
          Paint()
            ..color = const Color(0xFF334155).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant Mandap3DPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.result != result ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.pendingEdgeSourceId != pendingEdgeSourceId ||
        oldDelegate.activeHandleNodeId != activeHandleNodeId ||
        oldDelegate.dragPreviewLengthFeet != dragPreviewLengthFeet;
  }
}
