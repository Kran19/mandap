import 'dart:math' as math;
import 'package:meta/meta.dart';
import '../../../../core/geometry/length.dart';
import 'edge_id.dart';
import 'mandap_node.dart';
import 'node_id.dart';

/// Defines the structural rendering and cross-section profile of an edge.
enum EdgeProfile {
  /// Standard rectangular box truss (e.g. 4 chords and lattice).
  box,
  /// Single cylindrical tube (e.g. for individual lattice bracing or single pipes).
  singleTube,
}

/// Represents a horizontal truss edge run connecting two [MandapNode] instances.
@immutable
class MandapEdge {
  final EdgeId id;
  final NodeId startNodeId;
  final NodeId endNodeId;

  /// Optional manual requested length used in draft/form entry workflows
  /// before spatial node placement is finalized.
  final Length? requestedLength;

  /// The physical rendering and structural profile of this edge.
  /// Defaults to [EdgeProfile.box] for legacy compatibility if missing.
  final EdgeProfile? profile;

  const MandapEdge({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
    this.requestedLength,
    this.profile,
  });

  /// Calculates the actual geometric physical length of this edge
  /// given its start and end nodes.
  Length calculateGeometricLength(MandapNode startNode, MandapNode endNode) {
    assert(
      startNode.id == startNodeId,
      'startNode.id (${startNode.id}) does not match edge.startNodeId ($startNodeId)',
    );
    assert(
      endNode.id == endNodeId,
      'endNode.id (${endNode.id}) does not match edge.endNodeId ($endNodeId)',
    );

    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final double distanceInFeet = math.sqrt(dx * dx + dz * dz);

    return Length.fromFeet(distanceInFeet);
  }

  /// Returns the un-quantized geometric distance in feet between start and end nodes.
  double calculateGeometricDistanceFeet(
    MandapNode startNode,
    MandapNode endNode,
  ) {
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  MandapEdge copyWith({
    EdgeId? id,
    NodeId? startNodeId,
    NodeId? endNodeId,
    Length? requestedLength,
    EdgeProfile? profile,
  }) {
    return MandapEdge(
      id: id ?? this.id,
      startNodeId: startNodeId ?? this.startNodeId,
      endNodeId: endNodeId ?? this.endNodeId,
      requestedLength: requestedLength ?? this.requestedLength,
      profile: profile ?? this.profile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MandapEdge &&
          id == other.id &&
          startNodeId == other.startNodeId &&
          endNodeId == other.endNodeId &&
          requestedLength == other.requestedLength &&
          profile == other.profile);

  @override
  int get hashCode => Object.hash(id, startNodeId, endNodeId, requestedLength, profile);

  @override
  String toString() => 'MandapEdge($id, $startNodeId -> $endNodeId)';
}
