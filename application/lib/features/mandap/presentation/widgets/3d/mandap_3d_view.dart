import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/entities/node_id.dart';
import 'package:mandap/features/mandap/application/commands/move_node_command.dart';
import 'package:mandap/features/mandap/application/commands/resize_edge_command.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'mandap_3d_controller.dart';
import 'mandap_3d_painter.dart';
import 'math/drag_constraint_calculator.dart';
import '../../../application/coordinate_transform.dart';

/// Interactive 3D Mandap layout editor view supporting View Mode and Edit Mode.
class Mandap3DView extends StatefulWidget {
  final MandapEditorController controller;
  final Mandap3DController controller3D;

  const Mandap3DView({
    super.key,
    required this.controller,
    required this.controller3D,
  });

  @override
  State<Mandap3DView> createState() => _Mandap3DViewState();
}

class _Mandap3DViewState extends State<Mandap3DView> {
  Offset? _lastPointerPos;

  MandapLayout? _lastLayout;
  MandapCalculationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _syncSceneIfNeeded();
    widget.controller.addListener(_syncSceneIfNeeded);
  }

  @override
  void didUpdateWidget(covariant Mandap3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncSceneIfNeeded);
      widget.controller.addListener(_syncSceneIfNeeded);
    }
    _syncSceneIfNeeded();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncSceneIfNeeded);
    super.dispose();
  }

  void _syncSceneIfNeeded() {
    if (_lastLayout != widget.controller.layout ||
        _lastResult != widget.controller.result) {
      _lastLayout = widget.controller.layout;
      _lastResult = widget.controller.result;
      widget.controller3D.syncScene(
        widget.controller.layout,
        widget.controller.result,
      );
    }
  }

  void _onPointerDown(PointerDownEvent details, Size canvasSize) {
    _lastPointerPos = details.localPosition;
    final ray = widget.controller3D.createCameraRay(
      details.localPosition,
      canvasSize,
    );

    final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
      ray,
      widget.controller3D.mandapHeight,
    );
    final groundIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
      ray,
      0.0,
    );

    if (planeIntersection == null && groundIntersection == null) return;

    final pickedNodeId = widget.controller3D.registry.pickHandle(
      cameraRay: ray,
      hitRadiusFeet: 4.0,
    );

    final hitEdgeId = planeIntersection != null
        ? widget.controller3D.registry.pickBeam(
            planeIntersectionPoint: planeIntersection,
            maxHitDistanceFeet: 4.0,
          )
        : null;

    String? hitZoneId;
    if (planeIntersection != null) {
      for (final zone in widget.controller.layout.zones.reversed) {
        if (planeIntersection.x >= zone.left && planeIntersection.x <= zone.right &&
            planeIntersection.z >= zone.top && planeIntersection.z <= zone.bottom) {
          hitZoneId = zone.id;
          break;
        }
      }
    }

    switch (widget.controller.mode) {
      case EditorMode.view:
      case EditorMode.select:
      case EditorMode.addFlooring:
      case EditorMode.addStage:
        if (pickedNodeId != null) {
          widget.controller.selectNode(pickedNodeId);
        } else if (hitEdgeId != null) {
          widget.controller.selectEdge(hitEdgeId);
        } else {
          widget.controller.clearSelection();
        }
        setState(() {});
        break;

      case EditorMode.move:
        if (widget.controller.selectedEdgeId != null) {
          final edge = widget.controller.layout.getEdge(widget.controller.selectedEdgeId!);
          if (edge != null && pickedNodeId != null &&
              (pickedNodeId == edge.startNodeId || pickedNodeId == edge.endNodeId)) {
            final targetNode = widget.controller.layout.getNode(pickedNodeId);
            if (targetNode != null) {
              setState(() {
                widget.controller3D.isDraggingHandle = true;
                widget.controller3D.activeHandleNodeId = pickedNodeId;
                widget.controller3D.activeHandleEdgeId = edge.id;
                widget.controller3D.dragStartNodeX = targetNode.x;
                widget.controller3D.dragStartNodeZ = targetNode.z;
                if (planeIntersection != null) {
                  widget.controller3D.dragStartOffsetX = targetNode.x - planeIntersection.x;
                  widget.controller3D.dragStartOffsetZ = targetNode.z - planeIntersection.z;
                } else {
                  widget.controller3D.dragStartOffsetX = 0.0;
                  widget.controller3D.dragStartOffsetZ = 0.0;
                }
              });
              return;
            }
          }
        }

        if (pickedNodeId != null) {
          final node = widget.controller.layout.getNode(pickedNodeId);
          if (node != null) {
            setState(() {
              widget.controller.selectNode(pickedNodeId);
              widget.controller3D.isDraggingNode = true;
              widget.controller3D.activeHandleNodeId = pickedNodeId;
              widget.controller3D.dragStartNodeX = node.x;
              widget.controller3D.dragStartNodeZ = node.z;
              if (planeIntersection != null) {
                widget.controller3D.dragStartOffsetX = node.x - planeIntersection.x;
                widget.controller3D.dragStartOffsetZ = node.z - planeIntersection.z;
              } else {
                widget.controller3D.dragStartOffsetX = 0.0;
                widget.controller3D.dragStartOffsetZ = 0.0;
              }
            });
            return;
          }
        }
        break;

      case EditorMode.addNode:
      case EditorMode.addPole:
        final intersection = groundIntersection ?? planeIntersection;
        if (intersection != null) {
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize);
          final type = widget.controller.mode == EditorMode.addPole
              ? NodeType.pole
              : NodeType.corner;
          widget.controller.addNode(x: snappedX, z: snappedZ, type: type);
        }
        break;

      case EditorMode.addEdge:
        if (pickedNodeId != null) {
          widget.controller.handleAddEdgeTap(pickedNodeId);
        } else {
          final intersection = groundIntersection ?? planeIntersection;
          if (intersection != null) {
            final snappedX = DragConstraintCalculator.snapToGrid(
                intersection.x, widget.controller.subGridSize);
            final snappedZ = DragConstraintCalculator.snapToGrid(
                intersection.z, widget.controller.subGridSize);
            final newNodeId =
                widget.controller.addNode(x: snappedX, z: snappedZ);
            widget.controller.handleAddEdgeTap(newNodeId);
          }
        }
        break;

      case EditorMode.delete:
        if (pickedNodeId != null) {
          widget.controller.deleteNode(pickedNodeId);
        } else if (hitEdgeId != null) {
          widget.controller.deleteEdge(hitEdgeId);
        } else if (hitZoneId != null) {
          widget.controller.deleteZone(hitZoneId);
        }
        // Prevent orbit-camera drag on pointer move after a delete tap
        _lastPointerPos = null;
        setState(() {});
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent details, Size canvasSize) {
    if (_lastPointerPos == null) return;
    final delta = details.localPosition - _lastPointerPos!;
    _lastPointerPos = details.localPosition;

    if (widget.controller3D.isDraggingHandle &&
        widget.controller3D.activeHandleEdgeId != null &&
        widget.controller3D.activeHandleNodeId != null) {
      // Handle Edge Endpoint Resize Drag
      final edge = widget.controller.layout.getEdge(
        widget.controller3D.activeHandleEdgeId!,
      );
      if (edge != null) {
        final startNode = widget.controller.layout.getNode(edge.startNodeId);
        final endNode = widget.controller.layout.getNode(edge.endNodeId);

        if (startNode != null && endNode != null) {
          final ray = widget.controller3D.createCameraRay(
            details.localPosition,
            canvasSize,
          );
          final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
            ray,
            widget.controller3D.mandapHeight,
          );

          if (planeIntersection != null) {
            final movingIsEnd =
                widget.controller3D.activeHandleNodeId == endNode.id;
            final anchorNode = movingIsEnd ? startNode : endNode;
            final movingNode = movingIsEnd ? endNode : startNode;

            final currentLenFeet = widget.controller.layout
                .getEdgeLength(edge)
                .feet;

            final adjustedIntersection = v64.Vector3(
              planeIntersection.x + widget.controller3D.dragStartOffsetX,
              planeIntersection.y,
              planeIntersection.z + widget.controller3D.dragStartOffsetZ,
            );

            final dragResult = DragConstraintCalculator.calculateEdgeHandleDrag(
              startNode: anchorNode,
              endNode: movingNode,
              planeIntersectionPoint: adjustedIntersection,
              currentLengthFeet: currentLenFeet,
              gridSpacing: widget.controller.subGridSize,
            );

            if (dragResult.hasValueChanged) {
              setState(() {
                widget.controller3D.dragPreviewLengthFeet =
                    dragResult.snappedLength.feet;

                // Live preview update of domain node
                final updatedNodes = Map<NodeId, MandapNode>.from(
                  widget.controller.layout.nodes,
                );
                updatedNodes[widget.controller3D.activeHandleNodeId!] =
                    movingNode.copyWith(x: dragResult.newX, z: dragResult.newZ);
                final updatedLayout = MandapLayout(
                  nodes: updatedNodes,
                  edges: widget.controller.layout.edges,
                );
                widget.controller.loadCustomLayout(updatedLayout);
              });
            }
          }
        }
      }
    } else if (widget.controller3D.isDraggingNode &&
        widget.controller3D.activeHandleNodeId != null) {
      // Node Move Drag on X-Z plane
      final node = widget.controller.layout.getNode(
        widget.controller3D.activeHandleNodeId!,
      );
      if (node != null) {
        final ray = widget.controller3D.createCameraRay(
          details.localPosition,
          canvasSize,
        );
        final planeY = widget.controller3D.mandapHeight;
        final groundIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          planeY,
        );

        if (groundIntersection != null) {
          final adjustedIntersection = v64.Vector3(
            groundIntersection.x + widget.controller3D.dragStartOffsetX,
            groundIntersection.y,
            groundIntersection.z + widget.controller3D.dragStartOffsetZ,
          );

          final nodeResult = DragConstraintCalculator.calculateNodeDrag(
            currentNode: node,
            planeIntersectionPoint: adjustedIntersection,
            gridSpacing: widget.controller.subGridSize,
          );

          if (nodeResult.hasValueChanged) {
            setState(() {
              final updatedNodes = Map<NodeId, MandapNode>.from(
                widget.controller.layout.nodes,
              );
              updatedNodes[widget.controller3D.activeHandleNodeId!] = node
                  .copyWith(x: nodeResult.newX, z: nodeResult.newZ);
              final updatedLayout = MandapLayout(
                nodes: updatedNodes,
                edges: widget.controller.layout.edges,
              );
              widget.controller.loadCustomLayout(updatedLayout);
            });
          }
        }
      }
    } else {
      // Orbit camera on background drag
      widget.controller3D.orbitCamera(delta.dx, delta.dy);
    }
  }

  void _onPointerUp(PointerUpEvent details) {
    if (widget.controller3D.isDraggingHandle &&
        widget.controller3D.activeHandleEdgeId != null &&
        widget.controller3D.activeHandleNodeId != null) {
      final endNode = widget.controller.layout.getNode(
        widget.controller3D.activeHandleNodeId!,
      );
      if (endNode != null) {
        // Commit single ResizeEdgeCommand to controller command history
        final cmd = ResizeEdgeCommand(
          edgeId: widget.controller3D.activeHandleEdgeId!,
          movingNodeId: widget.controller3D.activeHandleNodeId!,
          oldX: widget.controller3D.dragStartNodeX,
          oldZ: widget.controller3D.dragStartNodeZ,
          newX: endNode.x,
          newZ: endNode.z,
        );
        widget.controller.executeCommand(cmd);
      }
    } else if (widget.controller3D.isDraggingNode &&
        widget.controller3D.activeHandleNodeId != null) {
      final node = widget.controller.layout.getNode(
        widget.controller3D.activeHandleNodeId!,
      );
      if (node != null) {
        // Commit single MoveNodeCommand to controller command history
        final cmd = MoveNodeCommand(
          nodeId: widget.controller3D.activeHandleNodeId!,
          oldX: widget.controller3D.dragStartNodeX,
          oldZ: widget.controller3D.dragStartNodeZ,
          newX: node.x,
          newZ: node.z,
        );
        widget.controller.executeCommand(cmd);
      }
    }

    setState(() {
      widget.controller3D.isDraggingHandle = false;
      widget.controller3D.isDraggingNode = false;
      widget.controller3D.activeHandleNodeId = null;
      widget.controller3D.activeHandleEdgeId = null;
      widget.controller3D.dragPreviewLengthFeet = null;
      _lastPointerPos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (d) => _onPointerDown(d, canvasSize),
          onPointerMove: (d) => _onPointerMove(d, canvasSize),
          onPointerUp: _onPointerUp,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.controller,
              widget.controller3D,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: canvasSize,
                painter: Mandap3DPainter(
                  layout: widget.controller.layout,
                  result: widget.controller.result,
                  controller: widget.controller3D,
                  selectedEdgeId: widget.controller.selectedEdgeId,
                  selectedNodeId: widget.controller.selectedNodeId,
                  pendingEdgeSourceId: widget.controller.pendingEdgeStartNodeId,
                  activeHandleNodeId: widget.controller3D.activeHandleNodeId,
                  dragPreviewLengthFeet:
                      widget.controller3D.dragPreviewLengthFeet,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
