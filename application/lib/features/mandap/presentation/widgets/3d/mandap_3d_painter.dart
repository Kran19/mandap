import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_edge.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/entities/mandap_zone.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/value_objects/pole_placement.dart';
import '../../../application/coordinate_transform.dart';
import 'mandap_3d_controller.dart';
import 'math/beam_transform_calculator.dart';

/// CustomPainter executing the CAD 3D rendering pipeline for Mandap truss structures.
/// Silver/aluminum dual-tone lattice chords, 4-chord vertical towers with square base plates,
/// blueprint grid, coordinate triad, and dimension badges.
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

    // 0. Paint Dark Blueprint Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F19),
    );

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
      1500.0,
    );

    Offset? project(v64.Vector3 worldPoint) {
      return CoordinateTransform.worldToScreen3D(
        worldPoint: worldPoint,
        viewportSize: size,
        viewMatrix: viewMatrix,
        projectionMatrix: projectionMatrix,
      );
    }

    // 1. Paint Ground Grid (Blueprint Dark Slate)
    _paintGroundGrid(canvas, project);

    // 2. Paint Custom Zones (Flooring, Stage)
    _paintZones(canvas, project);

    // 3. Paint Polymorphic Nodes (Stage, Carpet)
    _paintPolymorphicNodes(canvas, project);

    // 4. Paint 4-Chord Vertical Tower Poles with Ground Base Plates
    _paintPoles(canvas, project);

    // 5. Paint Silver / Aluminum Dual-Tone Lattice Beams
    _paintBeams(canvas, project);

    // 6. Paint Center Halo / Canopy Ring (if center node exists)
    _paintCenterHalo(canvas, project);

    // 7. Paint Node Handles
    _paintHandles(canvas, project);

    // 8. Paint Dimension Overlays for all beams
    _paintDimensionOverlays(canvas, size, project);

    // 9. Paint CAD Coordinate Triad Gizmo (Bottom-Left)
    _paintCoordinateGizmo(canvas, size, viewMatrix);
  }

  void _paintGroundGrid(Canvas canvas, Offset? Function(v64.Vector3) project) {
    const gridSize = 120.0;
    const step = 10.0;

    final fineGridPaint = Paint()
      ..color = const Color(0xFF151F30)
      ..strokeWidth = 1.0;

    final majorGridPaint = Paint()
      ..color = const Color(0xFF223249)
      ..strokeWidth = 1.5;

    for (double x = -gridSize; x <= gridSize; x += step) {
      final isMajor = (x % 50 == 0);
      final p1 = project(v64.Vector3(x, 0.0, -gridSize));
      final p2 = project(v64.Vector3(x, 0.0, gridSize));
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, isMajor ? majorGridPaint : fineGridPaint);
      }
    }

    for (double z = -gridSize; z <= gridSize; z += step) {
      final isMajor = (z % 50 == 0);
      final p1 = project(v64.Vector3(-gridSize, 0.0, z));
      final p2 = project(v64.Vector3(gridSize, 0.0, z));
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, isMajor ? majorGridPaint : fineGridPaint);
      }
    }

    // Origin marker lines
    final o = project(v64.Vector3(0, 0, 0));
    final ox = project(v64.Vector3(12, 0, 0));
    final oz = project(v64.Vector3(0, 0, 12));
    if (o != null && ox != null) {
      canvas.drawLine(
        o,
        ox,
        Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    if (o != null && oz != null) {
      canvas.drawLine(
        o,
        oz,
        Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintZones(Canvas canvas, Offset? Function(v64.Vector3) project) {
    for (final zone in layout.zones) {
      final left = math.min(zone.x1, zone.x2);
      final right = math.max(zone.x1, zone.x2);
      final top = math.min(zone.y1, zone.y2);
      final bottom = math.max(zone.y1, zone.y2);

      final h = zone.type == ZoneType.flooring ? 0.01 : 2.0;

      final color = zone.type == ZoneType.stage 
          ? const Color(0xFF1E293B).withValues(alpha: 0.9) 
          : const Color(0xFF0F172A).withValues(alpha: 0.7);

      final paint = Paint()..color = color..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = const Color(0xFF475569).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      const double tileSize = 10.0;
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
      if (node.type == NodeType.corner || node.type == NodeType.junction || node.type == NodeType.openEnd || node.type == NodeType.generatedSupport || node.type == NodeType.pole) {
        continue;
      }

      final w = node.width ?? 10.0;
      final d = node.depth ?? 10.0;
      final h = node.type == NodeType.carpet 
          ? 0.01 
          : node.height ?? (node.type == NodeType.pole ? controller.mandapHeight : 0.0);
          
      final elev = node.elevation;
      final rot = node.rotation;

      final halfW = w / 2;
      final halfD = d / 2;

      final localCorners = [
        v64.Vector3(-halfW, 0, -halfD),
        v64.Vector3(halfW, 0, -halfD),
        v64.Vector3(halfW, 0, halfD),
        v64.Vector3(-halfW, 0, halfD),
      ];

      final cosR = math.cos(rot);
      final sinR = math.sin(rot);

      final worldCornersBase = localCorners.map((c) {
        final rx = c.x * cosR - c.z * sinR;
        final rz = c.x * sinR + c.z * cosR;
        return v64.Vector3(node.x + rx, elev, node.z + rz);
      }).toList();

      final worldCornersTop = worldCornersBase.map((c) => v64.Vector3(c.x, c.y + h, c.z)).toList();

      final isSelected = node.id == selectedNodeId;

      if (node.type == NodeType.stage || node.type == NodeType.carpet) {
        final color = node.type == NodeType.stage 
            ? const Color(0xFF1E293B).withValues(alpha: 0.9) 
            : const Color(0xFF0F172A).withValues(alpha: 0.7);

        final paint = Paint()..color = color..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = (isSelected ? const Color(0xFF00F0FF) : const Color(0xFF475569))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : 1.0;

        _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: node.type == NodeType.stage);
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

    drawPoly(pt);
    drawPoly(pb);

    if (drawSides) {
      for (int i = 0; i < 4; i++) {
        final next = (i + 1) % 4;
        drawPoly([pb[i], pb[next], pt[next], pt[i]]);
      }
    }
  }

  void _paintPoles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    // 4-chord vertical aluminum box tower
    final chordPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final webPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final basePlateFill = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final basePlateBorder = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final boltPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    final height = controller.mandapHeight;
    const halfW = 0.4;
    const plateHalfW = 0.9;

    for (final pole in result.poles) {
      final bx = pole.x;
      final bz = pole.z;

      // 1. Draw Square Ground Base Plate (1.8 ft x 1.8 ft)
      final bp1 = project(v64.Vector3(bx - plateHalfW, 0.0, bz - plateHalfW));
      final bp2 = project(v64.Vector3(bx + plateHalfW, 0.0, bz - plateHalfW));
      final bp3 = project(v64.Vector3(bx + plateHalfW, 0.0, bz + plateHalfW));
      final bp4 = project(v64.Vector3(bx - plateHalfW, 0.0, bz + plateHalfW));

      if (bp1 != null && bp2 != null && bp3 != null && bp4 != null) {
        final platePath = Path()
          ..moveTo(bp1.dx, bp1.dy)
          ..lineTo(bp2.dx, bp2.dy)
          ..lineTo(bp3.dx, bp3.dy)
          ..lineTo(bp4.dx, bp4.dy)
          ..close();
        canvas.drawPath(platePath, basePlateFill);
        canvas.drawPath(platePath, basePlateBorder);

        // 4 corner bolts
        canvas.drawCircle(bp1, 1.8, boltPaint);
        canvas.drawCircle(bp2, 1.8, boltPaint);
        canvas.drawCircle(bp3, 1.8, boltPaint);
        canvas.drawCircle(bp4, 1.8, boltPaint);
      }

      // 2. 4 Vertical Chords for the Box Tower
      final cornerOffsets = [
        v64.Vector3(-halfW, 0, -halfW),
        v64.Vector3(halfW, 0, -halfW),
        v64.Vector3(halfW, 0, halfW),
        v64.Vector3(-halfW, 0, halfW),
      ];

      // Vertical diagonal webbing
      for (int i = 0; i < 4; i++) {
        final offA = cornerOffsets[i];
        final offB = cornerOffsets[(i + 1) % 4];

        for (double y = 0; y < height; y += 2.5) {
          final yEnd = math.min(y + 2.5, height);
          final p1 = project(v64.Vector3(bx + offA.x, y, bz + offA.z));
          final p2 = project(v64.Vector3(bx + offB.x, yEnd, bz + offB.z));
          if (p1 != null && p2 != null) canvas.drawLine(p1, p2, webPaint);

          final p3 = project(v64.Vector3(bx + offB.x, y, bz + offB.z));
          final p4 = project(v64.Vector3(bx + offA.x, yEnd, bz + offA.z));
          if (p3 != null && p4 != null) canvas.drawLine(p3, p4, webPaint);
        }
      }

      // 4 Main Chords
      for (final off in cornerOffsets) {
        final pBase = project(v64.Vector3(bx + off.x, 0.0, bz + off.z));
        final pTop = project(v64.Vector3(bx + off.x, height, bz + off.z));
        if (pBase != null && pTop != null) {
          canvas.drawLine(pBase, pTop, chordPaint);
        }
      }

      // Top corner junction cube
      final pCenterTop = project(v64.Vector3(bx, height, bz));
      if (pCenterTop != null) {
        canvas.drawCircle(pCenterTop, 3.5, Paint()..color = const Color(0xFFE2E8F0));
      }
    }
  }

  void _paintBeams(Canvas canvas, Offset? Function(v64.Vector3) project) {
    // Silver / Aluminum Dual-Tone Mandap Trusses
    final topChordPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // Bright Silver Aluminum
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final bottomChordPaint = Paint()
      ..color = const Color(0xFFCBD5E1) // Slate Silver
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final selectedChordPaint = Paint()
      ..color = const Color(0xFF00F0FF) // Electric Cyan Selection Highlight
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round;

    final webPaint = Paint()
      ..color = const Color(0xFF94A3B8) // Slate diagonal webbing
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final selectedWebPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final tubePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    final selectedTubePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final height = controller.mandapHeight;
    const halfW = 0.5;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final startY = startNode.elevation > 0 ? startNode.elevation : height;
        final endY = endNode.elevation > 0 ? endNode.elevation : height;
        final start = v64.Vector3(startNode.x, startY, startNode.z);
        final end = v64.Vector3(endNode.x, endY, endNode.z);
        
        final length = start.distanceTo(end);
        if (length < 0.001) continue;

        final isSelected = edge.id == selectedEdgeId;

        // Render as a single tube
        if (edge.profile == EdgeProfile.singleTube) {
          final tPaint = isSelected ? selectedTubePaint : tubePaint;
          final p1 = project(start);
          final p2 = project(end);
          if (p1 != null && p2 != null) {
             if (isSelected) {
               canvas.drawLine(p1, p2, Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.4)..strokeWidth = 10.0..strokeCap = StrokeCap.round);
             }
             canvas.drawLine(p1, p2, tPaint);
          }
          continue;
        }

        // Render as 4-chord silver box truss with diagonal webbing
        final cPaint = isSelected ? selectedChordPaint : topChordPaint;
        final bPaint = isSelected ? selectedChordPaint : bottomChordPaint;
        final wPaint = isSelected ? selectedWebPaint : webPaint;
        
        final dir = (end - start)..normalize();
        
        var up = v64.Vector3(0, 1, 0);
        if (dir.y.abs() > 0.999) {
           up = v64.Vector3(1, 0, 0);
        }
        
        final right = dir.cross(up)..normalize();
        up = right.cross(dir)..normalize();

        // 4 chords relative to centerline
        final offsets = [
          (right * -halfW) + (up * -halfW),
          (right * halfW) + (up * -halfW),
          (right * halfW) + (up * halfW),
          (right * -halfW) + (up * halfW),
        ];

        // Diagonal cross webbing
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

        // 4 Chords
        for (int i = 0; i < 4; i++) {
          final off = offsets[i];
          final p1 = project(start + off);
          final p2 = project(end + off);
          if (p1 != null && p2 != null) {
            if (isSelected) {
              canvas.drawLine(p1, p2, Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.4)..strokeWidth = 10.0..strokeCap = StrokeCap.round);
            }
            canvas.drawLine(p1, p2, (i >= 2) ? cPaint : bPaint);
          }
        }
      }
    }
  }

  void _paintCenterHalo(Canvas canvas, Offset? Function(v64.Vector3) project) {
    // Find center node or center position
    final centerNode = layout.nodes.values.firstWhere(
      (n) => n.id.value == 'node_center' || n.id.value.contains('center'),
      orElse: () => const MandapNode(id: NodeId('__none__'), x: -9999, z: -9999),
    );

    if (centerNode.x != -9999) {
      const radius = 3.5;
      const numSegments = 24;
      final haloPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final centerElevation = centerNode.elevation > 0 ? centerNode.elevation : controller.mandapHeight;
      final haloPoints = <Offset>[];
      for (int i = 0; i <= numSegments; i++) {
        final angle = (i / numSegments) * 2 * math.pi;
        final hx = centerNode.x + radius * math.cos(angle);
        final hz = centerNode.z + radius * math.sin(angle);
        final p = project(v64.Vector3(hx, centerElevation, hz));
        if (p != null) {
          haloPoints.add(p);
        }
      }

      if (haloPoints.length > 2) {
        final haloPath = Path()..moveTo(haloPoints.first.dx, haloPoints.first.dy);
        for (int i = 1; i < haloPoints.length; i++) {
          haloPath.lineTo(haloPoints[i].dx, haloPoints[i].dy);
        }
        haloPath.close();
        canvas.drawPath(haloPath, haloPaint);
      }
    }
  }

  void _paintHandles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final height = controller.mandapHeight;

    final startHandlePaint = Paint()..color = const Color(0xFF10B981); // Emerald Green
    final endHandlePaint = Paint()..color = const Color(0xFFEF4444); // Crimson
    final selectedNodePaint = Paint()..color = const Color(0xFFF59E0B); // Amber / Yellow highlight
    final pendingSourcePaint = Paint()..color = const Color(0xFF22C55E); // Bright Green

    for (final node in layout.nodes.values) {
      final p = project(v64.Vector3(node.x, height, node.z));
      if (p != null) {
        if (selectedEdgeId != null) {
          final selectedEdge = layout.getEdge(selectedEdgeId!);
          if (selectedEdge != null) {
            if (node.id == selectedEdge.startNodeId) {
              canvas.drawCircle(p, 7.0, startHandlePaint);
              continue;
            } else if (node.id == selectedEdge.endNodeId) {
              canvas.drawCircle(p, 7.0, endHandlePaint);
              continue;
            }
          }
        }

        if (node.id == pendingEdgeSourceId) {
          canvas.drawCircle(p, 8.0, pendingSourcePaint);
        } else if (node.id == selectedNodeId || node.id == activeHandleNodeId) {
          canvas.drawCircle(p, 8.0, selectedNodePaint);
          canvas.drawCircle(p, 11.0, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.0);
        } else {
          canvas.drawCircle(p, 4.5, Paint()..color = const Color(0xFFCBD5E1));
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
          color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFFE2E8F0),
          fontSize: isSelected ? 11 : 9.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          letterSpacing: 0.4,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        midpointScreen.dx - textPainter.width / 2.0,
        midpointScreen.dy - (isSelected ? 20.0 : 14.0),
      );

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textOffset.dx - 4,
          textOffset.dy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(3),
      );

      canvas.drawRRect(
        bgRect,
        Paint()..color = (isSelected ? const Color(0xFF0F172A) : const Color(0xFF1E293B)).withValues(alpha: 0.9),
      );

      canvas.drawRRect(
        bgRect,
        Paint()
          ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF475569)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 0.8,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  void _paintCoordinateGizmo(Canvas canvas, Size size, v64.Matrix4 viewMatrix) {
    // Bottom-left CAD coordinate triad
    final origin = Offset(52, size.height - 52);
    const axisLen = 32.0;

    // Extract upper 3x3 camera rotation to project unit axes
    final r = viewMatrix.getRotation();
    final xProj = Offset(r.entry(0, 0), -r.entry(1, 0)) * axisLen;
    final yProj = Offset(r.entry(0, 1), -r.entry(1, 1)) * axisLen;
    final zProj = Offset(r.entry(0, 2), -r.entry(1, 2)) * axisLen;

    // Gizmo backdrop circle
    canvas.drawCircle(
      origin,
      38,
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      origin,
      38,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    void drawAxis(Offset delta, Color color, String label) {
      final pEnd = origin + delta;
      canvas.drawLine(
        origin,
        pEnd,
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pEnd - Offset(tp.width / 2, tp.height / 2));
    }

    drawAxis(zProj, const Color(0xFF3B82F6), 'Z');
    drawAxis(xProj, const Color(0xFFEF4444), 'X');
    drawAxis(yProj, const Color(0xFF22C55E), 'Y');
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
