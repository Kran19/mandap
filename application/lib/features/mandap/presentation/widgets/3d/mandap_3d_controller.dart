import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import 'math/beam_transform_calculator.dart';
import 'math/render_entity_registry.dart';
import '../../../application/coordinate_transform.dart';

/// Production controller managing 3D camera, entity registry, raycast picking, and gesture interactions.
class Mandap3DController extends ChangeNotifier {
  double cameraAzimuth = 45.0 * math.pi / 180.0;
  double cameraElevation = 35.0 * math.pi / 180.0;
  double cameraDistance = 80.0;
  v64.Vector3 cameraCenterTarget = v64.Vector3(20.0, 5.0, 15.0);

  final RenderEntityRegistry registry = RenderEntityRegistry();

  bool isDraggingHandle = false;
  bool isDraggingNode = false;
  NodeId? activeHandleNodeId;
  EdgeId? activeHandleEdgeId;
  double? dragPreviewLengthFeet;

  double dragStartNodeX = 0.0;
  double dragStartNodeZ = 0.0;
  double dragStartOffsetX = 0.0;
  double dragStartOffsetZ = 0.0;

  /// Default visual mandap height in feet.
  double mandapHeight;

  Mandap3DController({this.mandapHeight = 10.0});

  void setMandapHeight(double h) {
    if (h > 0 && h != mandapHeight) {
      mandapHeight = h;
      notifyListeners();
    }
  }

  /// Fits camera view dynamically based on the bounding box of [layout].
  void fitCamera(MandapLayout layout) {
    if (layout.nodes.isEmpty) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minZ = double.infinity;
    double maxZ = -double.infinity;

    for (final node in layout.nodes.values) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.z < minZ) minZ = node.z;
      if (node.z > maxZ) maxZ = node.z;
    }

    final centerX = (minX + maxX) / 2.0;
    final centerZ = (minZ + maxZ) / 2.0;
    cameraCenterTarget = v64.Vector3(centerX, mandapHeight / 2.0, centerZ);

    final spanX = (maxX - minX).abs();
    final spanZ = (maxZ - minZ).abs();
    final maxSpan = math.max(spanX, spanZ);

    cameraDistance = math.max(40.0, maxSpan * 1.8);
    cameraAzimuth = 45.0 * math.pi / 180.0;
    cameraElevation = 35.0 * math.pi / 180.0;

    notifyListeners();
  }

  /// Resets camera to default orientation.
  void resetCamera() {
    cameraAzimuth = 45.0 * math.pi / 180.0;
    cameraElevation = 35.0 * math.pi / 180.0;
    cameraDistance = 80.0;
    notifyListeners();
  }

  /// Synchronizes 3D render entities from generic [layout] and [result].
  void syncScene(MandapLayout layout, MandapCalculationResult result) {
    registry.clear();

    // Register Handles for ALL nodes (so isolated nodes can be selected/deleted)
    for (final node in layout.nodes.values) {
      registry.registerHandle(
        HandleRenderEntity(
          nodeId: node.id,
          position: v64.Vector3(node.x, mandapHeight, node.z),
        ),
      );
    }

    // 1. Register Beams for EVERY MandapEdge (No preset branching)
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final transform = BeamTransformCalculator.calculate(
          startNode: startNode,
          endNode: endNode,
          height: mandapHeight,
        );

        registry.registerBeam(
          BeamRenderEntity(
            edgeId: edge.id,
            startNodeId: startNode.id,
            endNodeId: endNode.id,
            start: transform.start,
            end: transform.end,
            lengthFeet: transform.length,
          ),
        );

        // Register Node Handles at beam endpoints
        registry.registerHandle(
          HandleRenderEntity(nodeId: startNode.id, position: transform.start),
        );
        registry.registerHandle(
          HandleRenderEntity(nodeId: endNode.id, position: transform.end),
        );
      }
    }

    // 2. Register Poles strictly from MandapCalculationResult.poles
    for (int i = 0; i < result.poles.length; i++) {
      final polePlacement = result.poles[i];
      final poleId = PoleRenderId('pole_$i');

      registry.registerPole(
        PoleRenderEntity(
          id: poleId,
          polePlacement: polePlacement,
          basePosition: v64.Vector3(polePlacement.x, 0.0, polePlacement.z),
          heightFeet: mandapHeight,
        ),
      );
    }

    notifyListeners();
  }

  /// Orbit camera view.
  void orbitCamera(double deltaX, double deltaY) {
    cameraAzimuth += deltaX * 0.01;
    cameraElevation = (cameraElevation - deltaY * 0.01).clamp(
      0.05,
      math.pi / 2 - 0.05,
    );
    notifyListeners();
  }

  /// Zoom camera view.
  void zoomCamera(double zoomFactor) {
    cameraDistance = (cameraDistance * zoomFactor).clamp(20.0, 300.0);
    notifyListeners();
  }

  /// Creates a camera ray from screen touch position.
  v64.Ray createCameraRay(Offset localPos, Size viewportSize) {
    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      cameraDistance * cosElev * sinAzim,
      cameraDistance * sinElev,
      cameraDistance * cosElev * cosAzim,
    );

    final eyePosition = cameraCenterTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      cameraCenterTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = viewportSize.width / viewportSize.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      1000.0,
    );

    return CoordinateTransform.screen3DToWorldRay(
      screenPoint: Offset(localPos.dx, localPos.dy),
      viewportSize: viewportSize,
      viewMatrix: viewMatrix,
      projectionMatrix: projectionMatrix,
    );
  }

  /// Projects a 3D world point to 2D screen viewport position.
  Offset? worldToScreen(v64.Vector3 worldPoint, Size viewportSize) {
    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      cameraDistance * cosElev * sinAzim,
      cameraDistance * sinElev,
      cameraDistance * cosElev * cosAzim,
    );

    final eyePosition = cameraCenterTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      cameraCenterTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = viewportSize.width / viewportSize.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      1000.0,
    );

    final viewProj = projectionMatrix * viewMatrix;
    return CoordinateTransform.worldToScreen3D(
      worldPoint: worldPoint,
      viewportSize: viewportSize,
      viewMatrix: viewMatrix,
      projectionMatrix: projectionMatrix,
    );
  }
}
