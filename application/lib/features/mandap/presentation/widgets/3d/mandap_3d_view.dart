import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/application/commands/move_node_command.dart';
import 'package:mandap/features/mandap/application/commands/resize_edge_command.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'mandap_3d_controller.dart';
import 'mandap_3d_painter.dart';
import 'math/drag_constraint_calculator.dart';
import '../../../application/coordinate_transform.dart';
import '../../../domain/entities/truss_bay.dart';
import '../center_cross_support_required_dialog.dart';

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

  Offset? _downPointerPos;
  bool _wasMultiTouch = false;
  int _pointerCount = 0;

  void _onPointerDown(PointerDownEvent details, Size canvasSize) {
    if (_animController.isAnimating) {
      _animController.value = 1.0;
      _animController.stop();
    }
    _pointerCount++;
    _activePointers[details.pointer] = details.localPosition;
    _downPointerPos = details.localPosition;

    if (_activePointers.length >= 2 || _pointerCount >= 2) {
      _wasMultiTouch = true;
      _penHasDragged = false;
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

    // In view/select/move modes, setup drag targets if user begins dragging
    if (widget.controller.mode == EditorMode.view ||
        widget.controller.mode == EditorMode.select ||
        widget.controller.mode == EditorMode.move) {
      final centerCandidate = widget.controller.centerControlNode;
      final handleResult = widget.controller3D.registry.pickHandleWithDistance(
        cameraRay: ray,
        hitRadiusFeet: 3.5,
      );
      NodeId? pickedNodeId = handleResult.$1;

      if (pickedNodeId == null && centerCandidate != null) {
        final centerHitResult = widget.controller3D.registry.pickHandleWithDistance(
          cameraRay: ray,
          hitRadiusFeet: 10.0,
        );
        if (centerHitResult.$1 == centerCandidate.id) {
          pickedNodeId = centerHitResult.$1;
        }
      }

      if (pickedNodeId != null) {
        final node = widget.controller.layout.getNode(pickedNodeId);
        if (node != null && (node.isControlPoint || node.id.value.contains('center'))) {
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
        }
      }
    } else if (widget.controller.mode == EditorMode.addEdge) {
      _penPointerDownPos = details.localPosition;
      _penHasDragged = false;
    }
  }

  void _handleTap(Offset tapPos, Size canvasSize) {
    final ray = widget.controller3D.createCameraRay(
      tapPos,
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

    // 0. Check if user tapped the Center Dot to create Center Cross (+) in 3D
    final hasCrossEdges = widget.controller.layout.edges.values.any((e) => e.id.value.contains('cross') || e.id.value.contains('mid'));
    if (!hasCrossEdges) {
      final cX = widget.controller.centerControlNode?.x ?? (widget.controller.plotWidth / 2.0);
      final cZ = widget.controller.centerControlNode?.z ?? (widget.controller.plotDepth / 2.0);
      final centerWorld = v64.Vector3(cX, widget.controller3D.mandapHeight, cZ);
      final centerScreenPos = widget.controller3D.worldToScreen(centerWorld, canvasSize);

      bool isCenterTapped = false;
      if (centerScreenPos != null && (tapPos - centerScreenPos).distance < 36.0) {
        isCenterTapped = true;
      } else {
        final diff = centerWorld - ray.origin;
        final t = diff.dot(ray.direction);
        if (t > 0) {
          final proj = ray.origin + (ray.direction * t);
          if ((centerWorld - proj).length < 8.0) {
            isCenterTapped = true;
          }
        }
      }

      if (isCenterTapped) {
        final supportCheck = widget.controller.checkCenterCrossSupport();
        if (!supportCheck.canActivate) {
          CenterCrossSupportRequiredDialog.show(
            context,
            missingDirections: supportCheck.missingDirections,
          );
          return;
        }

        widget.controller.toggleCenterCross();
        widget.controller3D.fitCamera(widget.controller.layout);
        widget.controller3D.syncScene(widget.controller.layout, widget.controller.result);
        if (widget.controller.mode == EditorMode.addEdge) {
          widget.controller.cancelPenDrawing();
          widget.controller.setMode(EditorMode.view);
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Center Cross (+) created successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
        setState(() {});
        return;
      }
    }

    final centerCandidate = widget.controller.centerControlNode;
    final handleResult = widget.controller3D.registry.pickHandleWithDistance(
      cameraRay: ray,
      hitRadiusFeet: 3.5,
    );
    NodeId? pickedNodeId = handleResult.$1;
    double nodeDist = handleResult.$2;

    if (pickedNodeId == null && centerCandidate != null) {
      final centerHitResult = widget.controller3D.registry.pickHandleWithDistance(
        cameraRay: ray,
        hitRadiusFeet: 10.0,
      );
      if (centerHitResult.$1 == centerCandidate.id) {
        pickedNodeId = centerHitResult.$1;
        nodeDist = centerHitResult.$2;
      }
    }

    final beamResult = widget.controller3D.registry.pickBeamWithRayWithDistance(
      cameraRay: ray,
      maxHitDistanceFeet: 6.5,
    );
    EdgeId? hitEdgeId = beamResult.$1;
    double beamDist = beamResult.$2;

    if (hitEdgeId == null && planeIntersection != null) {
      hitEdgeId = widget.controller3D.registry.pickBeam(
        planeIntersectionPoint: planeIntersection,
        maxHitDistanceFeet: 6.0,
      );
      if (hitEdgeId != null) beamDist = 3.5;
    }

    final isCenterNode = pickedNodeId != null &&
        ((widget.controller.layout.getNode(pickedNodeId)?.isControlPoint ?? false) ||
            pickedNodeId.value.contains('center'));

    if (pickedNodeId != null && hitEdgeId != null && !isCenterNode && widget.controller.mode != EditorMode.addEdge) {
      if (beamDist <= nodeDist + 0.5) {
        pickedNodeId = null; // Prioritize selecting the truss beam in select mode
      }
    }

    switch (widget.controller.mode) {
      case EditorMode.view:
      case EditorMode.select:
      case EditorMode.move:
        if (pickedNodeId != null) {
          final node = widget.controller.layout.getNode(pickedNodeId);
          if (node != null) {
            widget.controller.selectNode(pickedNodeId);
            widget.controller.deselectBay();
          }
        } else if (hitEdgeId != null) {
          final edge = widget.controller.layout.getEdge(hitEdgeId);
          if (edge != null) {
            final hitPt = planeIntersection ?? groundIntersection;
            widget.controller.selectEdge(hitEdgeId, worldX: hitPt?.x, worldZ: hitPt?.z);
            widget.controller.deselectBay();
          }
        } else {
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
          final hitPt = planeIntersection ?? groundIntersection;
          widget.controller.deleteEdge(hitEdgeId, worldX: hitPt?.x, worldZ: hitPt?.z);
          widget.controller.clearSelection();
        }
        _lastPointerPos = null;
        setState(() {});
        break;

      case EditorMode.addPole:
        if (pickedNodeId != null) {
          widget.controller.setNodeSupport(pickedNodeId, NodeSupport.pole);
          widget.controller.autoConnectUnconnectedPoles();
        } else if (hitEdgeId != null) {
          final intersection = planeIntersection ?? groundIntersection;
          widget.controller.splitEdgeWithPole(
            hitEdgeId,
            x: intersection?.x,
            z: intersection?.z,
            elevation: widget.controller3D.mandapHeight,
          );
          widget.controller.autoConnectUnconnectedPoles();
        } else {
          final intersection = groundIntersection ?? planeIntersection;
          if (intersection != null) {
            final snappedX = DragConstraintCalculator.snapToGrid(
                intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
            final snappedZ = DragConstraintCalculator.snapToGrid(
                intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);

            final passingEdgeId = widget.controller.findEdgePassingThrough(snappedX, snappedZ);
            if (passingEdgeId != null) {
              widget.controller.splitEdgeWithPole(
                passingEdgeId,
                x: snappedX,
                z: snappedZ,
                elevation: widget.controller3D.mandapHeight,
              );
            } else {
              widget.controller.addNodeNamed(
                x: snappedX,
                z: snappedZ,
                type: NodeType.pole,
                elevation: 0.0,
                support: NodeSupport.pole,
              );
            }
            widget.controller.autoConnectUnconnectedPoles();
          }
        }
        break;

      case EditorMode.addNode:
        final intersection = groundIntersection ?? planeIntersection;
        if (intersection != null) {
          final snappedX = DragConstraintCalculator.snapToGrid(
              intersection.x, widget.controller.subGridSize).clamp(-250.0, 250.0);
          final snappedZ = DragConstraintCalculator.snapToGrid(
              intersection.z, widget.controller.subGridSize).clamp(-250.0, 250.0);
          widget.controller.addNodeNamed(
            x: snappedX,
            z: snappedZ,
            type: NodeType.corner,
            elevation: widget.controller3D.mandapHeight,
            support: NodeSupport.none,
          );
        }
        break;

      case EditorMode.addEdge:
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
              content: Text('First node selected. Tap another node to connect.'),
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
                content: Text('✓ Truss connected successfully! Tap another pole to continue.'),
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
                content: Text('✓ Truss member created! Tap another point to continue.'),
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

    // 1. Two-finger pinch-to-zoom and two-finger pan (works in all modes including pencil)
    if (_activePointers.length >= 2) {
      _wasMultiTouch = true;
      _penHasDragged = false;
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
    } else {
      _lastPinchDistance = null;
      _lastPanMidpoint = null;
    }

    if (_wasMultiTouch) {
      // During release phase of multi-touch gesture, ignore single-finger move events
      return;
    }

    // 2. Single finger handling
    if (widget.controller.mode == EditorMode.addEdge) {
      if (_penPointerDownPos != null &&
          (details.localPosition - _penPointerDownPos!).distance > 22.0) {
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
      return; // Absolute lock: 1-finger touches strictly draw truss with camera orbit/pan locked!
    }

    if (_lastPointerPos == null) return;
    final delta = details.localPosition - _lastPointerPos!;
    _lastPointerPos = details.localPosition;

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

  void _onPointerUp(PointerUpEvent details, Size canvasSize) {
    final distFromDown = _downPointerPos != null
        ? (details.localPosition - _downPointerPos!).distance
        : 0.0;
    final hadMultiTouch = _wasMultiTouch;
    final hadPenDragged = _penHasDragged;
    final isSingleTap = !hadMultiTouch && _pointerCount <= 1 && distFromDown <= 22.0;

    _activePointers.remove(details.pointer);
    if (_activePointers.length < 2) {
      _lastPinchDistance = null;
      _lastPanMidpoint = null;
    }

    if (isSingleTap) {
      _handleTap(details.localPosition, canvasSize);
    } else if (!hadMultiTouch &&
        widget.controller.mode == EditorMode.addEdge &&
        hadPenDragged &&
        widget.controller.penState == PenState.waitingForEnd &&
        widget.controller.penStartPoint != null) {
      final ray = widget.controller3D.createCameraRay(
        details.localPosition,
        canvasSize,
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

      if (dist > 1.0 || (hitNodeId != null && hitNodeId != widget.controller.penStartNodeId)) {
        widget.controller.createTrussMember(
          targetEndPoint: currentPt,
          targetEndNodeId: hitNodeId,
          startNodeId: widget.controller.penStartNodeId,
          endNodeId: hitNodeId,
        );
        widget.controller.cancelPenDrawing();
        widget.controller3D.syncScene(widget.controller.layout, widget.controller.result);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Truss created successfully! Continue drawing or close pencil when done.'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        widget.controller.cancelPenDrawing();
      }
      setState(() {});
      return;
    }
    if (!hadMultiTouch &&
        widget.controller3D.isDraggingHandle &&
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

    } else if (!hadMultiTouch &&
        widget.controller3D.isDraggingEdge &&
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

    if (_activePointers.isEmpty) {
      _pointerCount = 0;
      _wasMultiTouch = false;
      _penHasDragged = false;
      _downPointerPos = null;
      _penPointerDownPos = null;
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
          onPointerUp: (d) => _onPointerUp(d, canvasSize),
          onPointerCancel: (d) {
            _activePointers.remove(d.pointer);
            if (_activePointers.length < 2) {
              _lastPinchDistance = null;
              _lastPanMidpoint = null;
            }
            if (_activePointers.isEmpty) {
              _pointerCount = 0;
              _wasMultiTouch = false;
              _penHasDragged = false;
              _downPointerPos = null;
              _penPointerDownPos = null;
            }
            _lastPointerPos = _activePointers.isEmpty ? null : _activePointers.values.first;
          },
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              if (widget.controller.mode == EditorMode.addEdge) return;
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
