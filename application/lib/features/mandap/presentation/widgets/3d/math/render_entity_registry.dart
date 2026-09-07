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
    double hitRadiusFeet = 4.0,
  }) {
    NodeId? closestNodeId;
    double minDistance = hitRadiusFeet;

    final rayOriginX = cameraRay.origin.x;
    final rayOriginZ = cameraRay.origin.z;
    final rayDirX = cameraRay.direction.x;
    final rayDirZ = cameraRay.direction.z;
    final dirLengthSq = rayDirX * rayDirX + rayDirZ * rayDirZ;

    for (final handle in _handles.values) {
      final hX = handle.position.x;
      final hZ = handle.position.z;

      double dist;
      if (dirLengthSq < 1e-6) {
        dist = math.sqrt((hX - rayOriginX) * (hX - rayOriginX) +
            (hZ - rayOriginZ) * (hZ - rayOriginZ));
      } else {
        // Distance from point (hX, hZ) to line in XZ plane
        final cross = (hX - rayOriginX) * rayDirZ - (hZ - rayOriginZ) * rayDirX;
        dist = cross.abs() / math.sqrt(dirLengthSq);

        // Check if the Y intersection is within the pole's vertical bounds (0 to 10 ft)
        // We add some margin (-5 to 15) to make tapping easier
        final t = ((hX - rayOriginX) * rayDirX + (hZ - rayOriginZ) * rayDirZ) /
            dirLengthSq;
        final hitY = cameraRay.origin.y + t * cameraRay.direction.y;
        if (hitY < -5.0 || hitY > 15.0) continue;
      }

      if (dist <= minDistance) {
        minDistance = dist;
        closestNodeId = handle.nodeId;
      }
    }

    return closestNodeId;
  }

  /// Performs 3D raycast picking to find the closest beam entity.
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
