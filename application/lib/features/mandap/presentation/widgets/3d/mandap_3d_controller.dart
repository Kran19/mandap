import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../domain/value_objects/pole_placement.dart';
import 'math/beam_transform_calculator.dart';
import 'math/render_entity_registry.dart';
import '../../../application/coordinate_transform.dart';

/// Production controller managing 3D camera, entity registry, raycast picking, and gesture interactions.
class Mandap3DController extends ChangeNotifier {
  double cameraAzimuth = 45.0 * math.pi / 180.0;
  double cameraElevation = 32.0 * math.pi / 180.0; // Cinematic eye-level perspective matching professional event truss reference
  double cameraDistance = 140.0;
  v64.Vector3 cameraCenterTarget = v64.Vector3(50.0, 5.0, 50.0);

  final RenderEntityRegistry registry = RenderEntityRegistry();

  bool isDraggingHandle = false;
  bool isDraggingNode = false;
  bool isDraggingEdge = false;
  NodeId? activeHandleNodeId;
  EdgeId? activeHandleEdgeId;
  double? dragPreviewLengthFeet;

  double dragStartNodeX = 0.0;
  double dragStartNodeZ = 0.0;
  double dragStartOffsetX = 0.0;
  double dragStartOffsetZ = 0.0;
  double dragStartPlaneX = 0.0;
  double dragStartPlaneZ = 0.0;
  double dragStartNode1X = 0.0;
  double dragStartNode1Z = 0.0;
  double dragStartNode2X = 0.0;
  double dragStartNode2Z = 0.0;

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
  void fitCamera(MandapLayout layout, {Size? viewportSize}) {
    if (layout.nodes.isEmpty) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minZ = double.infinity;
    double maxZ = -double.infinity;
    double maxElev = mandapHeight;

    for (final node in layout.nodes.values) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.z < minZ) minZ = node.z;
      if (node.z > maxZ) maxZ = node.z;
      if (node.elevation > maxElev) maxElev = node.elevation;
    }

    if (maxElev > 0) {
      mandapHeight = maxElev;
    }

    final centerX = (minX + maxX) / 2.0;
    final centerZ = (minZ + maxZ) / 2.0;
    cameraCenterTarget = v64.Vector3(centerX, maxElev * 0.20, centerZ);

    final spanX = (maxX - minX).abs();
    final spanZ = (maxZ - minZ).abs();
    final maxSpan = math.max(spanX, spanZ);

    // Calculate aspect ratio (default to mobile portrait 0.48 if not provided)
    final aspect = (viewportSize != null && viewportSize.height > 0)
        ? (viewportSize.width / viewportSize.height).clamp(0.2, 3.0)
        : 0.48;

    const tanHalfFovY = 0.41421356;
    final tanHalfFovX = tanHalfFovY * aspect;

    // Projected bounding width at 45° azimuth and 32° elevation
    final horizSpan = (spanX + spanZ) * 0.7071 + 35.0;
    final vertSpan = (spanX + spanZ) * 0.7071 * 0.53 + maxElev * 0.85 + 35.0;

    final distNeededX = horizSpan / (2.0 * tanHalfFovX);
    final distNeededY = vertSpan / (2.0 * tanHalfFovY);
    final neededDist = math.max(distNeededX, distNeededY) * 1.15;

    cameraDistance = math.max(115.0, math.max(neededDist, maxSpan * 1.55 + maxElev * 1.2));
    cameraAzimuth = 45.0 * math.pi / 180.0;
    cameraElevation = 32.0 * math.pi / 180.0; // Cinematic eye-level perspective

    notifyListeners();
  }

  /// Resets camera to default orientation.
  void resetCamera() {
    cameraAzimuth = 45.0 * math.pi / 180.0;
    cameraElevation = 32.0 * math.pi / 180.0;
    cameraDistance = 140.0;
    notifyListeners();
  }

  /// Sets camera to direct overhead top-down view centered on the layout, fitting the whole structure.
  void setTopDownView({MandapLayout? layout, Size? viewportSize, bool notify = true}) {
    cameraAzimuth = 0.0;
    cameraElevation = 88.5 * math.pi / 180.0; // Direct overhead angle
    if (layout != null && layout.nodes.isNotEmpty) {
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minZ = double.infinity;
      double maxZ = -double.infinity;
      double maxElev = mandapHeight;

      for (final node in layout.nodes.values) {
        if (node.x < minX) minX = node.x;
        if (node.x > maxX) maxX = node.x;
        if (node.z < minZ) minZ = node.z;
        if (node.z > maxZ) maxZ = node.z;
        if (node.elevation > maxElev) maxElev = node.elevation;
      }
      final centerX = (minX + maxX) / 2.0;
      final centerZ = (minZ + maxZ) / 2.0;
      cameraCenterTarget = v64.Vector3(centerX, maxElev * 0.20, centerZ);
      final spanX = (maxX - minX).abs();
      final spanZ = (maxZ - minZ).abs();

      // Calculate aspect ratio (default to mobile portrait 0.48 if not provided)
      final aspect = (viewportSize != null && viewportSize.height > 0)
          ? (viewportSize.width / viewportSize.height).clamp(0.2, 3.0)
          : 0.48;

      // In perspective matrix with 45 deg fovY:
      // tan(fovY / 2) = tan(22.5 deg) ~ 0.41421356
      const tanHalfFovY = 0.41421356;
      final tanHalfFovX = tanHalfFovY * aspect;

      // Add generous margin (padding 45 ft) so rails and dimension badges do not obscure structure
      final paddedSpanX = spanX + 45.0;
      final paddedSpanZ = spanZ + 45.0;

      final distNeededForWidth = paddedSpanX / (2.0 * tanHalfFovX);
      final distNeededForHeight = paddedSpanZ / (2.0 * tanHalfFovY);

      cameraDistance = math.max(220.0, math.max(distNeededForWidth, distNeededForHeight) * 1.25);
    } else {
      cameraDistance = 280.0;
    }
    if (notify) notifyListeners();
  }

  /// Synchronizes 3D render entities from generic [layout] and [result].
  void syncScene(MandapLayout layout, MandapCalculationResult result) {
    registry.clear();

    double maxElev = 0.0;
    for (final node in layout.nodes.values) {
      if (node.elevation > maxElev) maxElev = node.elevation;
    }
    if (maxElev > 0) {
      mandapHeight = maxElev;
    }

    // Register Handles for ALL nodes using node elevation
    for (final node in layout.nodes.values) {
      registry.registerHandle(
        HandleRenderEntity(
          nodeId: node.id,
          position: v64.Vector3(node.x, node.elevation, node.z),
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

    // 2. Register Poles strictly from MandapCalculationResult.poles and layout nodes
    final renderedKeys = <String>{};
    for (int i = 0; i < result.poles.length; i++) {
      final polePlacement = result.poles[i];
      final poleId = PoleRenderId('pole_');

      // Determine the exact top elevation of this tower from layout nodes or edges
      MandapNode? matchingNode;
      if (polePlacement.sourceNodeId != null) {
        matchingNode = layout.getNode(polePlacement.sourceNodeId!);
      }
      if (matchingNode == null) {
        for (final n in layout.nodes.values) {
          if ((n.x - polePlacement.x).abs() < 0.5 && (n.z - polePlacement.z).abs() < 0.5) {
            matchingNode = n;
            break;
          }
        }
      }

      double poleHeight = (matchingNode != null && matchingNode.elevation > 0)
          ? matchingNode.elevation
          : mandapHeight;

      registry.registerPole(
        PoleRenderEntity(
          id: poleId,
          polePlacement: polePlacement,
          basePosition: v64.Vector3(polePlacement.x, 0.0, polePlacement.z),
          heightFeet: poleHeight,
        ),
      );
      renderedKeys.add('_');
    }

    // Also register any nodes designated with NodeSupport.pole or NodeType.corner
    int extraPoleIndex = 0;
    for (final node in layout.nodes.values) {
      if (node.type == NodeType.controlPoint || node.type == NodeType.carpet || node.type == NodeType.stage) {
        continue;
      }
      if (node.support == NodeSupport.pole || node.type == NodeType.corner) {
        final key = '_';
        if (!renderedKeys.contains(key)) {
          final polePlacement = PolePlacement(
            id: 'node_pole_',
            x: node.x,
            z: node.z,
            reason: node.type == NodeType.corner ? PoleReason.corner : PoleReason.manual,
            sourceNodeId: node.id,
          );
          registry.registerPole(
            PoleRenderEntity(
              id: PoleRenderId('pole_node__'),
              polePlacement: polePlacement,
              basePosition: v64.Vector3(node.x, 0.0, node.z),
              heightFeet: node.elevation > 0 ? node.elevation : mandapHeight,
            ),
          );
          renderedKeys.add(key);
        }
      }
    }

    notifyListeners();
  }

  /// Orbit camera view with refined, buttery-smooth sensitivity.
  void orbitCamera(double deltaX, double deltaY) {
    cameraAzimuth += deltaX * 0.0038;
    cameraElevation = (cameraElevation - deltaY * 0.0038).clamp(
      0.15, // Keep camera above turf to eliminate clipping
      math.pi / 2 - 0.05,
    );
    notifyListeners();
  }

  /// Zoom camera view.
  void zoomCamera(double zoomFactor) {
    cameraDistance = (cameraDistance * zoomFactor).clamp(15.0, 10000.0);
    notifyListeners();
  }

  /// Pan camera view parallel to the view plane with smooth 1:1 finger tracking.
  void panCamera(double deltaX, double deltaY) {
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);
    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);

    // Camera right vector in world space: (cosAzim, 0, -sinAzim)
    final right = v64.Vector3(cosAzim, 0.0, -sinAzim);

    // Camera up vector in world space: (-sinAzim * sinElev, cosElev, -cosAzim * sinElev)
    final up = v64.Vector3(-sinAzim * sinElev, cosElev, -cosAzim * sinElev);

    // Scaling factor proportional to distance so pan moves with finger
    final scale = (cameraDistance / 950.0);
    final displacement = (right * (-deltaX * scale)) + (up * (deltaY * scale));

    cameraCenterTarget += displacement;
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
      math.max(15000.0, cameraDistance * 4.0),
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
      math.max(15000.0, cameraDistance * 4.0),
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
