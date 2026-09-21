import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import '../../../domain/entities/truss_bay.dart';

/// Interactive 3D Mandap layout editor view supporting View Mode and Edit Mode.
class Mandap3DView extends StatefulWidget {
  final MandapEditorController controller;
  final Mandap3DController controller3D;
  final bool runAnimationOnLoad;
  final VoidCallback? onAnimationCompleted;

  const Mandap3DView({
    super.key,
    required this.controller,
    required this.controller3D,
    this.runAnimationOnLoad = true,
    this.onAnimationCompleted,
  });

  @override
  State<Mandap3DView> createState() => _Mandap3DViewState();
}

class _Mandap3DViewState extends State<Mandap3DView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animProgress;

  Offset? _lastPointerPos;
  final Map<int, Offset> _activePointers = {};
  double? _lastPinchDistance;
  Offset? _lastPanMidpoint;
  Offset? _penPointerDownPos;
  bool _penHasDragged = false;

  MandapLayout? _lastLayout;
  MandapCalculationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );

    _animController.addListener(() {
      if (mounted) setState(() {});
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationCompleted?.call();
      }
    });

    if (widget.runAnimationOnLoad) {
      _animController.forward(from: 0.0);
    } else {
      _animController.value = 1.0;
    }

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
    _animController.dispose();
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
    if (_animController.isAnimating) {
      _animController.value = 1.0;
      _animController.stop();
    }
    _activePointers[details.pointer] = details.localPosition;
    if (_activePointers.length == 2) {
      final pts = _activePointers.values.toList();
      _lastPinchDistance = (pts[0] - pts[1]).distance;
      _lastPanMidpoint = (pts[0] + pts[1]) / 2.0;
      _lastPointerPos = null;
      return;
    }
    if (_activePointers.length > 2) return;

    _lastPointerPos = details.localPosition;
    _lastPanMidpoint = null;
    _lastPinchDistance = null;
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

    final centerCandidate = widget.controller.centerControlNode;
    NodeId? pickedNodeId = widget.controller3D.registry.pickHandle(
      cameraRay: ray,
      hitRadiusFeet: 7.0,
    );
    if (pickedNodeId == null && centerCandidate != null) {
      final centerHit = widget.controller3D.registry.pickHandle(
        cameraRay: ray,
        hitRadiusFeet: 14.0,
      );
      if (centerHit == centerCandidate.id) {
        pickedNodeId = centerHit;
      }
    }

    final hitEdgeId = widget.controller3D.registry.pickBeamWithRay(
      cameraRay: ray,
      maxHitDistanceFeet: 7.0,
    ) ?? (planeIntersection != null
        ? widget.controller3D.registry.pickBeam(
            planeIntersectionPoint: planeIntersection,
            maxHitDistanceFeet: 6.0,
          )
        : null);

    switch (widget.controller.mode) {
      case EditorMode.view:
      case EditorMode.select:
      case EditorMode.move:
        if (pickedNodeId != null) {
          final node = widget.controller.layout.getNode(pickedNodeId);
          if (node != null) {
            widget.controller.selectNode(pickedNodeId);
            final isMiddleNode = node.isControlPoint || node.id.value.contains('center');
            // ALLOW DRAGGING THE MIDDLE TRUSS NODE IN ALL VIEW/SELECT/MOVE MODES!
            if (isMiddleNode) {
              final nodeElev = node.elevation > 0 ? node.elevation : widget.controller3D.mandapHeight;
              final nodePlaneIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
                ray,
                nodeElev,
              ) ?? CoordinateTransform.rayHorizontalPlaneIntersection(
                ray,
                0.0,
              );
              setState(() {
                widget.controller3D.isDraggingNode = true;
                widget.controller3D.activeHandleNodeId = pickedNodeId;
                widget.controller3D.dragStartNodeX = node.x;
                widget.controller3D.dragStartNodeZ = node.z;
                if (nodePlaneIntersection != null) {
                  widget.controller3D.dragStartOffsetX = node.x - nodePlaneIntersection.x;
                  widget.controller3D.dragStartOffsetZ = node.z - nodePlaneIntersection.z;
                } else {
                  widget.controller3D.dragStartOffsetX = 0.0;
                  widget.controller3D.dragStartOffsetZ = 0.0;
                }
              });
              return;
            } else if (widget.controller.mode == EditorMode.move) {
              final nodeElev = node.elevation > 0 ? node.elevation : widget.controller3D.mandapHeight;
              final nodePlaneIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
                ray,
                nodeElev,
              );
              setState(() {
                widget.controller3D.isDraggingNode = true;
                widget.controller3D.activeHandleNodeId = pickedNodeId;
                widget.controller3D.dragStartNodeX = node.x;
                widget.controller3D.dragStartNodeZ = node.z;
                if (nodePlaneIntersection != null) {
                  widget.controller3D.dragStartOffsetX = node.x - nodePlaneIntersection.x;
                  widget.controller3D.dragStartOffsetZ = node.z - nodePlaneIntersection.z;
                } else {
                  widget.controller3D.dragStartOffsetX = 0.0;
                  widget.controller3D.dragStartOffsetZ = 0.0;
                }
              });
              return;
            } else {
              // In view/select mode, do not drag non-center nodes — preserve camera orbit/pan!
              setState(() {
                widget.controller3D.isDraggingNode = false;
                widget.controller3D.isDraggingHandle = false;
                widget.controller3D.activeHandleNodeId = null;
              });
            }
          }
        } else if (hitEdgeId != null) {
          final edge = widget.controller.layout.getEdge(hitEdgeId);
          if (edge != null) {
            widget.controller.selectEdge(hitEdgeId);
            final n1 = widget.controller.layout.getNode(edge.startNodeId);
            final n2 = widget.controller.layout.getNode(edge.endNodeId);
            final isCrossEdge = edge.id.value.contains('cross') || edge.id.value.contains('center');
            final centerNode = widget.controller.centerControlNode ??
                ((n1 != null && (n1.isControlPoint || n1.id.value.contains('center') || n1.id.value.contains('mid')))
                    ? n1
                    : ((n2 != null && (n2.isControlPoint || n2.id.value.contains('center') || n2.id.value.contains('mid'))) ? n2 : null));

            if (centerNode != null && (isCrossEdge || centerNode.id == n1?.id || centerNode.id == n2?.id)) {
              final nodeElev = centerNode.elevation > 0 ? centerNode.elevation : widget.controller3D.mandapHeight;
              final nodePlaneIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
                ray,
                nodeElev,
              ) ?? CoordinateTransform.rayHorizontalPlaneIntersection(
                ray,
                0.0,
              );
              setState(() {
                widget.controller3D.isDraggingNode = true;
                widget.controller3D.activeHandleNodeId = centerNode.id;
                widget.controller3D.dragStartNodeX = centerNode.x;
                widget.controller3D.dragStartNodeZ = centerNode.z;
                if (nodePlaneIntersection != null) {
                  widget.controller3D.dragStartOffsetX = centerNode.x - nodePlaneIntersection.x;
                  widget.controller3D.dragStartOffsetZ = centerNode.z - nodePlaneIntersection.z;
                } else {
                  widget.controller3D.dragStartOffsetX = 0.0;
                  widget.controller3D.dragStartOffsetZ = 0.0;
                }
              });
              return;
            } else {
              setState(() {
                widget.controller3D.isDraggingEdge = false;
                widget.controller3D.isDraggingHandle = false;
                widget.controller3D.activeHandleEdgeId = null;
              });
            }
          }
        } else {
          // Reviewer correction 5: Test ray horizontal interaction plane against TrussBay world coordinates
          final testPoint = groundIntersection ?? planeIntersection;
          TrussBay? hitBay;
          if (testPoint != null) {
            for (final bay in widget.controller.bays) {
              if (bay.containsPoint(testPoint.x, testPoint.z, 0.0)) {
                hitBay = bay;
                break;
              }
            }
          }

          if (hitBay != null) {
            widget.controller.selectBay(hitBay.id);
          } else {
            widget.controller.clearSelection();
            widget.controller.deselectBay();
          }
        }
        setState(() {});
        break;

      case EditorMode.delete:
        final hitPole = widget.controller3D.registry.pickPoleWithRay(cameraRay: ray);
        if (hitPole != null) {
          widget.controller.deletePole(hitPole.polePlacement);
          widget.controller.clearSelection();
        } else if (pickedNodeId != null) {
          widget.controller.deleteNode(pickedNodeId);
          widget.controller.clearSelection();
        } else if (hitEdgeId != null) {
          widget.controller.deleteEdge(hitEdgeId);
          widget.controller.clearSelection();
        }
        _lastPointerPos = null;
        setState(() {});
        break;

      case EditorMode.addNode:
      case EditorMode.addPole:
        final intersection = groundIntersection ?? planeIntersection;
        if (intersection != null) {
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final type = widget.controller.mode == EditorMode.addPole
              ? NodeType.pole
              : NodeType.corner;
          final elev = widget.controller.mode == EditorMode.addPole
              ? 0.0
              : widget.controller3D.mandapHeight;
          widget.controller.addNodeNamed(x: snappedX, z: snappedZ, type: type, elevation: elev);
        }
        break;

      case EditorMode.addEdge:
        _penPointerDownPos = details.localPosition;
        _penHasDragged = false;

        v64.Vector3 tappedPt;
        NodeId? hitNodeId = pickedNodeId;

        if (pickedNodeId != null) {
          final pickedNode = widget.controller.layout.getNode(pickedNodeId);
          if (pickedNode != null) {
            tappedPt = v64.Vector3(pickedNode.x, pickedNode.elevation, pickedNode.z);
          } else {
            break;
          }
        } else {
          final intersection = planeIntersection ?? groundIntersection;
          if (intersection == null) break;
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);
          tappedPt = v64.Vector3(snappedX, widget.controller3D.mandapHeight, snappedZ);
        }

        if (widget.controller.penState == PenState.waitingForStart || widget.controller.penStartPoint == null) {
          widget.controller.setPenStartPoint(
            tappedPt,
            startNodeId: hitNodeId,
            snapToClosestTruss: true,
          );
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('First truss selected. Tap another node to connect.'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF0284C7),
            ),
          );
          setState(() {});
        } else if (widget.controller.penState == PenState.waitingForEnd) {
          final startNodeId = widget.controller.penStartNodeId;
          if (hitNodeId != null && hitNodeId != startNodeId) {
            widget.controller.createTrussMember(
              targetEndPoint: tappedPt,
              targetEndNodeId: hitNodeId,
              startNodeId: startNodeId,
              endNodeId: hitNodeId,
            );
            widget.controller.cancelPenDrawing();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Truss connected successfully!'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
            setState(() {});
          } else if ((tappedPt - widget.controller.penStartPoint!).length > 1.0) {
            widget.controller.createTrussMember(
              targetEndPoint: tappedPt,
              targetEndNodeId: hitNodeId,
            );
            widget.controller.cancelPenDrawing();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Truss member created!'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
            setState(() {});
          }
        }
        break;

      default:
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent details, Size canvasSize) {
    if (_animController.isAnimating) return;
    _activePointers[details.pointer] = details.localPosition;

    if (_activePointers.length >= 2) {
      final pts = _activePointers.values.toList();
      final currentDistance = (pts[0] - pts[1]).distance;
      final currentMidpoint = (pts[0] + pts[1]) / 2.0;

      if (_lastPinchDistance != null && _lastPinchDistance! > 10.0) {
        final scaleRatio = currentDistance / _lastPinchDistance!;
        const double sensitivity3D = 0.22;
        final zoomFactor = 1.0 - (scaleRatio - 1.0) * sensitivity3D;
        widget.controller3D.zoomCamera(zoomFactor);
      }
      _lastPinchDistance = currentDistance;

      if (_lastPanMidpoint != null) {
        final panDelta = currentMidpoint - _lastPanMidpoint!;
        widget.controller3D.panCamera(panDelta.dx, panDelta.dy);
      }
      _lastPanMidpoint = currentMidpoint;
      _lastPointerPos = null;
      return;
    }

    if (_lastPointerPos == null) return;
    final delta = details.localPosition - _lastPointerPos!;
    _lastPointerPos = details.localPosition;

    if (widget.controller.mode == EditorMode.addEdge) {
      if (_penPointerDownPos != null &&
          (details.localPosition - _penPointerDownPos!).distance > 24.0) {
        _penHasDragged = true;
      }
      if (widget.controller.penState == PenState.waitingForEnd &&
          widget.controller.penStartPoint != null) {
        final ray = widget.controller3D.createCameraRay(
          details.localPosition,
          canvasSize,
        );
        final hoverNodeId = widget.controller3D.registry.pickHandle(
          cameraRay: ray,
          hitRadiusFeet: 7.0,
        );
        final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          widget.controller3D.mandapHeight,
        );
        final groundIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          0.0,
        );
        final intersection = planeIntersection ?? groundIntersection;

        v64.Vector3 currentPt;
        if (hoverNodeId != null) {
          final n = widget.controller.layout.getNode(hoverNodeId);
          if (n != null) {
            currentPt = v64.Vector3(n.x, n.elevation, n.z);
          } else {
            currentPt = widget.controller.penStartPoint!;
          }
        } else if (intersection != null) {
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);
          currentPt = v64.Vector3(snappedX, widget.controller3D.mandapHeight, snappedZ);
        } else {
          return;
        }

        widget.controller.updatePenPreview(currentPt, hoverNodeId: hoverNodeId);
        setState(() {});
      }
      return; // Do NOT orbit camera while drawing pencil!
    }

    if (widget.controller3D.isDraggingHandle ||
        widget.controller3D.isDraggingNode ||
        widget.controller3D.isDraggingEdge) {
      final ray = widget.controller3D.createCameraRay(
        details.localPosition,
        canvasSize,
      );

      if (widget.controller3D.isDraggingHandle &&
          widget.controller3D.activeHandleEdgeId != null &&
          widget.controller3D.activeHandleNodeId != null) {
        final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          widget.controller3D.mandapHeight,
        );

        if (planeIntersection != null) {
          final rawWorldX = planeIntersection.x + widget.controller3D.dragStartOffsetX;
          final rawWorldZ = planeIntersection.z + widget.controller3D.dragStartOffsetZ;

          final edge = widget.controller.layout.getEdge(
            widget.controller3D.activeHandleEdgeId!,
          );
          if (edge != null) {
            final fixedNodeId = edge.startNodeId == widget.controller3D.activeHandleNodeId
                ? edge.endNodeId
                : edge.startNodeId;
            final fixedNode = widget.controller.layout.getNode(fixedNodeId);

            if (fixedNode != null) {
              final nodeResult = DragConstraintCalculator.calculateNodeDrag(
                currentNode: fixedNode,
                planeIntersectionPoint: planeIntersection,
                gridSpacing: widget.controller.subGridSize,
              );

              if (nodeResult.hasValueChanged) {
                setState(() {
                  final updatedNodes = Map<NodeId, MandapNode>.from(
                    widget.controller.layout.nodes,
                  );
                  final node = widget.controller.layout.getNode(
                    widget.controller3D.activeHandleNodeId!,
                  )!;
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
        }
      } else if (widget.controller3D.isDraggingNode &&
          widget.controller3D.activeHandleNodeId != null) {
        final node = widget.controller.layout.getNode(
          widget.controller3D.activeHandleNodeId!,
        );

        if (node != null && (node.isControlPoint || node.id.value.contains('center'))) {
          final nodeElev = node.elevation > 0 ? node.elevation : widget.controller3D.mandapHeight;
          final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
            ray,
            nodeElev,
          ) ?? CoordinateTransform.rayHorizontalPlaneIntersection(
            ray,
            0.0,
          );

          if (planeIntersection != null) {
            // Free multi-directional movement: Center point can move in ALL directions (left/right, front/back)
            final rawWorldX = planeIntersection.x + widget.controller3D.dragStartOffsetX;
            final rawWorldZ = planeIntersection.z + widget.controller3D.dragStartOffsetZ;

            final minX = 5.0;
            final maxX = widget.controller.plotWidth > 10.0 ? widget.controller.plotWidth - 5.0 : 95.0;
            final minZ = 5.0;
            final maxZ = widget.controller.plotDepth > 10.0 ? widget.controller.plotDepth - 5.0 : 95.0;

            final clampedX = DragConstraintCalculator.snapToGrid(
              rawWorldX.clamp(minX, maxX),
              widget.controller.subGridSize,
            );
            final clampedZ = DragConstraintCalculator.snapToGrid(
              rawWorldZ.clamp(minZ, maxZ),
              widget.controller.subGridSize,
            );

            if ((clampedX - node.x).abs() > 0.001 || (clampedZ - node.z).abs() > 0.001) {
              setState(() {
                widget.controller.adjustCenterPosition(newX: clampedX, newZ: clampedZ);
              });
            }
          }
        }
      } else if (widget.controller3D.isDraggingEdge &&
          widget.controller3D.activeHandleEdgeId != null) {
        final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          widget.controller3D.mandapHeight,
        );

        if (planeIntersection != null) {
          final rawDeltaX = planeIntersection.x - widget.controller3D.dragStartPlaneX;
          final rawDeltaZ = planeIntersection.z - widget.controller3D.dragStartPlaneZ;
          final snappedDeltaX = DragConstraintCalculator.snapToGrid(rawDeltaX, widget.controller.subGridSize);
          final snappedDeltaZ = DragConstraintCalculator.snapToGrid(rawDeltaZ, widget.controller.subGridSize);

          final edge = widget.controller.layout.getEdge(widget.controller3D.activeHandleEdgeId!);
          if (edge != null) {
            final n1 = widget.controller.layout.getNode(edge.startNodeId);
            final n2 = widget.controller.layout.getNode(edge.endNodeId);
            if (n1 != null && n2 != null) {
              final newX1 = widget.controller3D.dragStartNode1X + snappedDeltaX;
              final newZ1 = widget.controller3D.dragStartNode1Z + snappedDeltaZ;
              final newX2 = widget.controller3D.dragStartNode2X + snappedDeltaX;
              final newZ2 = widget.controller3D.dragStartNode2Z + snappedDeltaZ;

              if (newX1 != n1.x || newZ1 != n1.z || newX2 != n2.x || newZ2 != n2.z) {
                setState(() {
                  final updatedNodes = Map<NodeId, MandapNode>.from(
                    widget.controller.layout.nodes,
                  );
                  updatedNodes[n1.id] = n1.copyWith(x: newX1, z: newZ1);
                  updatedNodes[n2.id] = n2.copyWith(x: newX2, z: newZ2);
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
      }
    } else {
      widget.controller3D.orbitCamera(delta.dx, delta.dy);
    }
  }

  void _onPointerUp(PointerUpEvent details) {
    _activePointers.remove(details.pointer);
    if (_activePointers.length < 2) {
      _lastPinchDistance = null;
      _lastPanMidpoint = null;
    }

    if (widget.controller.mode == EditorMode.addEdge) {
      if (widget.controller.penState == PenState.waitingForEnd &&
          widget.controller.penStartPoint != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final size = renderBox?.size ?? const Size(800, 600);
        final ray = widget.controller3D.createCameraRay(
          details.localPosition,
          size,
        );
        final hitNodeId = widget.controller3D.registry.pickHandle(
          cameraRay: ray,
          hitRadiusFeet: 7.0,
        );
        final planeIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          widget.controller3D.mandapHeight,
        );
        final groundIntersection = CoordinateTransform.rayHorizontalPlaneIntersection(
          ray,
          0.0,
        );
        final intersection = planeIntersection ?? groundIntersection;

        v64.Vector3 currentPt;
        if (hitNodeId != null) {
          final n = widget.controller.layout.getNode(hitNodeId);
          currentPt = n != null
              ? v64.Vector3(n.x, n.elevation, n.z)
              : widget.controller.penStartPoint!;
        } else if (intersection != null) {
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);
          currentPt = v64.Vector3(snappedX, widget.controller3D.mandapHeight, snappedZ);
        } else {
          currentPt = widget.controller.penPreviewEndPoint ?? widget.controller.penStartPoint!;
        }

        final dist = (currentPt - widget.controller.penStartPoint!).length;

        if (_penHasDragged) {
          // Drag-to-draw release
          if (dist > 1.0 || (hitNodeId != null && hitNodeId != widget.controller.penStartNodeId)) {
            widget.controller.createTrussMember(
              targetEndPoint: currentPt,
              targetEndNodeId: hitNodeId,
            );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Truss created successfully!'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          } else {
            widget.controller.cancelPenDrawing();
          }
          setState(() {});
          return;
        } else {
          // Stationary tap: check if it's the second tap
          if ((hitNodeId != null && hitNodeId != widget.controller.penStartNodeId) || dist > 2.0) {
            widget.controller.createTrussMember(
              targetEndPoint: currentPt,
              targetEndNodeId: hitNodeId,
            );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Truss created successfully!'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            setState(() {});
            return;
          }
          // Otherwise, it was the first tap setting start point. Stay in waitingForEnd!
        }
      }
      return;
    }
    if (widget.controller3D.isDraggingHandle &&
        widget.controller3D.activeHandleEdgeId != null &&
        widget.controller3D.activeHandleNodeId != null) {
      final endNode = widget.controller.layout.getNode(
        widget.controller3D.activeHandleNodeId!,
      );
      if (endNode != null) {
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

    } else if (widget.controller3D.isDraggingEdge &&
        widget.controller3D.activeHandleEdgeId != null) {
      final edge = widget.controller.layout.getEdge(widget.controller3D.activeHandleEdgeId!);
      if (edge != null) {
        final n1 = widget.controller.layout.getNode(edge.startNodeId);
        final n2 = widget.controller.layout.getNode(edge.endNodeId);
        if (n1 != null &&
            (n1.x != widget.controller3D.dragStartNode1X ||
             n1.z != widget.controller3D.dragStartNode1Z)) {
          widget.controller.executeCommand(MoveNodeCommand(
            nodeId: n1.id,
            oldX: widget.controller3D.dragStartNode1X,
            oldZ: widget.controller3D.dragStartNode1Z,
            newX: n1.x,
            newZ: n1.z,
          ));
        }
        if (n2 != null &&
            (n2.x != widget.controller3D.dragStartNode2X ||
             n2.z != widget.controller3D.dragStartNode2Z)) {
          widget.controller.executeCommand(MoveNodeCommand(
            nodeId: n2.id,
            oldX: widget.controller3D.dragStartNode2X,
            oldZ: widget.controller3D.dragStartNode2Z,
            newX: n2.x,
            newZ: n2.z,
          ));
        }
      }
    }

    setState(() {
      widget.controller3D.isDraggingHandle = false;
      widget.controller3D.isDraggingNode = false;
      widget.controller3D.isDraggingEdge = false;
      widget.controller3D.activeHandleNodeId = null;
      widget.controller3D.activeHandleEdgeId = null;
      widget.controller3D.dragPreviewLengthFeet = null;
      _lastPointerPos = _activePointers.isEmpty ? null : _activePointers.values.first;
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
          onPointerCancel: (d) {
            _activePointers.remove(d.pointer);
            if (_activePointers.length < 2) {
              _lastPinchDistance = null;
              _lastPanMidpoint = null;
            }
            _lastPointerPos = _activePointers.isEmpty ? null : _activePointers.values.first;
          },
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              final zoomDelta = signal.scrollDelta.dy > 0 ? 1.05 : 0.95;
              widget.controller3D.zoomCamera(zoomDelta);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric Outdoor Sky Backdrop (Screen-space distant horizon)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF6BA3D6), // Open sunny daytime sky
                      Color(0xFF90C2E7), // Atmospheric soft sky
                      Color(0xFFC7E2F5), // Horizon haze
                      Color(0xFFE8F2FA), // Horizon warm glow
                    ],
                    stops: [0.0, 0.40, 0.75, 1.0],
                  ),
                ),
              ),

              // 3D Canvas
              AnimatedBuilder(
                animation: Listenable.merge([
                  widget.controller,
                  widget.controller3D,
                  _animProgress,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    size: canvasSize,
                    painter: Mandap3DPainter(
                      layout: widget.controller.layout,
                      result: widget.controller.result,
                      controller: widget.controller3D,
                      editorController: widget.controller,
                      selectedEdgeId: widget.controller.selectedEdgeId,
                      selectedNodeId: widget.controller.selectedNodeId,
                      selectedBayId: widget.controller.selectedBayId,
                      pendingEdgeSourceId: widget.controller.pendingEdgeStartNodeId,
                      activeHandleNodeId: widget.controller3D.activeHandleNodeId,
                      dragPreviewLengthFeet:
                          widget.controller3D.dragPreviewLengthFeet,
                      animationProgress: _animProgress.value,
                      plotWidth: widget.controller.plotWidth,
                      plotDepth: widget.controller.plotDepth,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
