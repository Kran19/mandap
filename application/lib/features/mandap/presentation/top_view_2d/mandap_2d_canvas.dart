import 'package:flutter/material.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/node_id.dart';
import '../../application/mandap_editor_controller.dart';
import '../../application/editor_mode.dart';
import 'mandap_2d_painter.dart';

class Mandap2DCanvas extends StatefulWidget {
  final MandapEditorController controller;

  const Mandap2DCanvas({super.key, required this.controller});

  @override
  State<Mandap2DCanvas> createState() => _Mandap2DCanvasState();
}

class _Mandap2DCanvasState extends State<Mandap2DCanvas> {
  final TransformationController _transformController = TransformationController();
  
  // We use the same deterministic coordinate mapping as the painter
  static const double pixelsPerFoot = 20.0;
  
  NodeId? _draggingNodeId;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Offset _screenToWorld(Offset screenLocalOffset) {
    // Inverse transform the local screen offset through the InteractiveViewer's matrix
    final matrix = _transformController.value.clone();
    matrix.invert();
    
    // Applying the inverse matrix to the point
    final worldPixels = MatrixUtils.transformPoint(matrix, screenLocalOffset);
    
    return Offset(
      worldPixels.dx / pixelsPerFoot,
      worldPixels.dy / pixelsPerFoot,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.controller.mode == EditorMode.view) return;
    
    final worldPos = _screenToWorld(details.localPosition);
    
    // Hit test: check nodes first (hit radius 3.0 feet in world space = 9.0 squared)
    MandapNode? bestNode;
    double minDistance = double.infinity;
    for (final node in widget.controller.layout.nodes.values) {
      final dx = node.x - worldPos.dx;
      final dz = node.z - worldPos.dy;
      final distance = (dx * dx + dz * dz);
      if (distance < 9.0 && distance < minDistance) {
        minDistance = distance;
        bestNode = node;
      }
    }

    if (bestNode != null) {
      if (bestNode.type == NodeType.controlPoint ||
          bestNode.isControlPoint ||
          bestNode.id.value.contains('center')) {
        if (!widget.controller.hasCenterCross) {
          widget.controller.toggleCenterCross();
        }
      }
      if (widget.controller.mode == EditorMode.select || widget.controller.mode == EditorMode.move) {
        widget.controller.selectNode(bestNode.id);
        _draggingNodeId = bestNode.id;
        return;
      } else if (widget.controller.mode == EditorMode.addEdge) {
        widget.controller.handleAddEdgeTap(bestNode.id);
        return;
      }
    }

    final centerPos = Offset(widget.controller.plotWidth / 2.0, widget.controller.plotDepth / 2.0);
    final distToCenterSq = (worldPos.dx - centerPos.dx) * (worldPos.dx - centerPos.dx) +
        (worldPos.dy - centerPos.dy) * (worldPos.dy - centerPos.dy);
    if (distToCenterSq < 25.0 && !widget.controller.hasCenterCross) {
      widget.controller.toggleCenterCross();
      return;
    }
    
    // Hit test edges if in select mode
    if (widget.controller.mode == EditorMode.select) {
      for (final edge in widget.controller.layout.edges.values) {
        final start = widget.controller.layout.getNode(edge.startNodeId);
        final end = widget.controller.layout.getNode(edge.endNodeId);
        if (start == null || end == null) continue;
        
        final hit = _pointLineDistance(
          worldPos.dx, worldPos.dy,
          start.x, start.z,
          end.x, end.z,
        );
        
        if (hit < 0.5) { // 0.5 feet tolerance
          widget.controller.selectEdge(edge.id, worldX: worldPos.dx, worldZ: worldPos.dy);
          widget.controller.deselectBay();
          return;
        }
      }

      // Hit test truss bays
      for (final bay in widget.controller.bays) {
        if (bay.containsPoint(worldPos.dx, worldPos.dy)) {
          widget.controller.clearSelection();
          widget.controller.selectBay(bay.id);
          return;
        }
      }
      
      // If nothing hit, clear selection
      widget.controller.clearSelection();
      widget.controller.deselectBay();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.controller.mode != EditorMode.move && widget.controller.mode != EditorMode.select) return;
    if (_draggingNodeId == null) return;

    final worldPos = _screenToWorld(details.localPosition);
    
    // Apply grid snap
    final snappedX = _snap(worldPos.dx, widget.controller.baseGridSize, widget.controller.subGridSize);
    final snappedZ = _snap(worldPos.dy, widget.controller.baseGridSize, widget.controller.subGridSize);

    final draggedNode = widget.controller.layout.nodes[_draggingNodeId];
    if (draggedNode != null &&
        (draggedNode.isControlPoint ||
         draggedNode.type == NodeType.controlPoint ||
         draggedNode.id.value.contains('center'))) {
      // Dynamic center cross relocation: moves whole center structure together
      widget.controller.adjustCenterPosition(
        newX: snappedX,
        newZ: snappedZ,
      );
    } else {
      widget.controller.moveNode(
        nodeId: _draggingNodeId!,
        newX: snappedX,
        newZ: snappedZ,
      );
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _draggingNodeId = null;
  }

  double _snap(double value, double major, double minor) {
    if (minor <= 0) return value;
    return (value / minor).roundToDouble() * minor;
  }

  double _pointLineDistance(double px, double py, double x1, double y1, double x2, double y2) {
    final a = px - x1;
    final b = py - y1;
    final c = x2 - x1;
    final d = y2 - y1;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;
    
    double param = -1;
    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * c;
      yy = y1 + param * d;
    }

    final dx = px - xx;
    final dy = py - yy;
    
    // return squared distance for speed, or sqrt for actual
    return (dx * dx + dy * dy); // returns squared distance, so check threshold appropriately squared
  }

  @override
  Widget build(BuildContext context) {
    // If Pen is OFF (view mode), panning is enabled. If Pen is ON, it is disabled.
    final bool isPenMode = widget.controller.mode != EditorMode.view;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          panEnabled: !isPenMode,
          scaleEnabled: true,
          minScale: 0.1,
          maxScale: 10.0,
          constrained: false, // Allows infinite canvas feel
          boundaryMargin: const EdgeInsets.all(10000),
          child: GestureDetector(
            onTapDown: isPenMode ? _handleTapDown : null,
            onPanUpdate: isPenMode ? _handlePanUpdate : null,
            onPanEnd: isPenMode ? _handlePanEnd : null,
            child: CustomPaint(
              // Large bounded area for the custom painter since InteractiveViewer is unbounded
              size: const Size(10000, 10000),
              painter: Mandap2DPainter(
                layout: widget.controller.layout,
                result: widget.controller.result,
                selectedEdgeId: widget.controller.selectedEdgeId,
                bays: widget.controller.bays,
                selectedBayId: widget.controller.selectedBayId,
                showMarkings: widget.controller.showMarkings,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
