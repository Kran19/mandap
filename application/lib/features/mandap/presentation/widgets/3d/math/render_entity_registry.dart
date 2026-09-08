import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/edge_id.dart';
import '../../../../domain/entities/node_id.dart';
import '../../../../domain/value_objects/pole_placement.dart';

/// Identifier for a rendered support pole.
class PoleRenderId {
  final String value;
  const PoleRenderId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoleRenderId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PoleRenderId($value)';
}

/// Render entity representing a horizontal or diagonal top truss beam in 3D.
class BeamRenderEntity {
  final EdgeId edgeId;
  final NodeId startNodeId;
  final NodeId endNodeId;
  final v64.Vector3 start;
  final v64.Vector3 end;
  final double lengthFeet;

  const BeamRenderEntity({
    required this.edgeId,
    required this.startNodeId,
    required this.endNodeId,
    required this.start,
    required this.end,
    required this.lengthFeet,
  });
}

/// Render entity representing an interactive endpoint node handle in 3D.
class HandleRenderEntity {
  final NodeId nodeId;
  final v64.Vector3 position;

  const HandleRenderEntity({required this.nodeId, required this.position});
}

/// Render entity representing a vertical support pole in 3D.
class PoleRenderEntity {
  final PoleRenderId id;
  final PolePlacement polePlacement;
  final v64.Vector3 basePosition;
  final double heightFeet;

  const PoleRenderEntity({
    required this.id,
    required this.polePlacement,
    required this.basePosition,
    required this.heightFeet,
  });
}

/// Bidirectional entity registry maintaining stable 3D render entity identities.
class RenderEntityRegistry {
  final Map<EdgeId, BeamRenderEntity> _beams = {};
  final Map<NodeId, HandleRenderEntity> _handles = {};
  final Map<PoleRenderId, PoleRenderEntity> _poles = {};

  Map<EdgeId, BeamRenderEntity> get beams => Map.unmodifiable(_beams);
  Map<NodeId, HandleRenderEntity> get handles => Map.unmodifiable(_handles);
  Map<PoleRenderId, PoleRenderEntity> get poles => Map.unmodifiable(_poles);

  void clear() {
    _beams.clear();
    _handles.clear();
    _poles.clear();
  }

  void registerBeam(BeamRenderEntity entity) {
    _beams[entity.edgeId] = entity;
  }

  void registerHandle(HandleRenderEntity entity) {
    _handles[entity.nodeId] = entity;
  }

  void registerPole(PoleRenderEntity entity) {
    _poles[entity.id] = entity;
  }

  BeamRenderEntity? getBeam(EdgeId edgeId) => _beams[edgeId];
  HandleRenderEntity? getHandle(NodeId nodeId) => _handles[nodeId];
  PoleRenderEntity? getPole(PoleRenderId poleId) => _poles[poleId];

  /// Performs 3D raycast picking to find the closest handle entity.
  NodeId? pickHandle({
    required v64.Ray cameraRay,
    double hitRadiusFeet = 7.0,
  }) {
    NodeId? closestNodeId;
    double minDistance = hitRadiusFeet;

    final rayOrigin = cameraRay.origin;
    final rayDir = cameraRay.direction.normalized();

    for (final handle in _handles.values) {
      final pos = handle.position;
      final v = pos - rayOrigin;
      final t = v.dot(rayDir);
      if (t < 0.0) continue; // Behind camera

      final proj = rayOrigin + rayDir * t;
      final dist = (pos - proj).length;

      if (dist <= minDistance) {
        minDistance = dist;
        closestNodeId = handle.nodeId;
      }
    }

    return closestNodeId;
  }

  /// Performs 3D ray-to-segment distance picking directly in 3D for beam entities.
  EdgeId? pickBeamWithRay({
    required v64.Ray cameraRay,
    double maxHitDistanceFeet = 7.0,
  }) {
    EdgeId? closestEdgeId;
    double minDistance = maxHitDistanceFeet;

    final rayOrigin = cameraRay.origin;
    final rayDir = cameraRay.direction.normalized();

    for (final beam in _beams.values) {
      final p1 = beam.start;
      final p2 = beam.end;
      final segDir = p2 - p1;
      final segLengthSq = segDir.length2;

      if (segLengthSq < 1e-6) {
        final v = p1 - rayOrigin;
        final t = v.dot(rayDir);
        if (t < 0) continue;
        final proj = rayOrigin + rayDir * t;
        final d = (p1 - proj).length;
        if (d <= minDistance) {
          minDistance = d;
          closestEdgeId = beam.edgeId;
        }
        continue;
      }

      final w0 = rayOrigin - p1;
      final a = rayDir.dot(rayDir); // 1.0
      final b = rayDir.dot(segDir);
      final c = segLengthSq;
      final d = rayDir.dot(w0);
      final e = segDir.dot(w0);

      final denom = a * c - b * b;
      double sc, tc;

      if (denom < 1e-6) {
        tc = 0.0;
        sc = d / a;
      } else {
        tc = (a * e - b * d) / denom;
        tc = tc.clamp(0.0, 1.0);
        sc = (b * tc - d) / a;
      }

      if (sc < 0.0) {
        sc = 0.0;
        tc = (e / c).clamp(0.0, 1.0);
      }

      final closestOnRay = rayOrigin + rayDir * sc;
      final closestOnSeg = p1 + segDir * tc;
      final dist = (closestOnRay - closestOnSeg).length;

      if (dist <= minDistance) {
        minDistance = dist;
        closestEdgeId = beam.edgeId;
      }
    }

    return closestEdgeId;
  }

  /// Performs 3D raycast picking to find the closest beam entity via plane intersection.
  EdgeId? pickBeam({
    required v64.Vector3 planeIntersectionPoint,
    double maxHitDistanceFeet = 4.0,
  }) {
    EdgeId? closestEdgeId;
    double minDistance = maxHitDistanceFeet;

    final target = v64.Vector3(
      planeIntersectionPoint.x,
      planeIntersectionPoint.y,
      planeIntersectionPoint.z,
    );

    for (final beam in _beams.values) {
      final p1 = beam.start;
      final p2 = beam.end;

      // Distance from intersection point to segment
      final segmentDir = p2 - p1;
      final segLength = segmentDir.length;

      double dist;
      if (segLength < 1e-6) {
        dist = (target - p1).length;
      } else {
        final t = ((target - p1).dot(segmentDir) / (segLength * segLength))
            .clamp(0.0, 1.0);
        final projection = p1 + segmentDir * t;
        dist = (target - projection).length;
      }

      if (dist <= minDistance) {
        minDistance = dist;
        closestEdgeId = beam.edgeId;
      }
    }

    return closestEdgeId;
  }
}
