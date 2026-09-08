import 'package:meta/meta.dart';
import '../entities/edge_id.dart';
import '../entities/node_id.dart';

/// Indicates the structural reason why a pole was placed.
enum PoleReason {
  /// Corner or structural junction node.
  corner,

  /// Generated intermediate support to satisfy max unsupported span rule (<= 30 ft).
  generatedMaxSpan,

  /// Manually placed pole by user.
  manual,
}

/// Represents a vertical support pole placement in the layout.
@immutable
class PolePlacement {
  final String id;
  final double x;
  final double z;
  final PoleReason reason;
  final NodeId? sourceNodeId;
  final EdgeId? sourceEdgeId;

  const PolePlacement({
    required this.id,
    required this.x,
    required this.z,
    required this.reason,
    this.sourceNodeId,
    this.sourceEdgeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolePlacement &&
          id == other.id &&
          x == other.x &&
          z == other.z &&
          reason == other.reason &&
          sourceNodeId == other.sourceNodeId &&
          sourceEdgeId == other.sourceEdgeId);

  @override
  int get hashCode => Object.hash(id, x, z, reason, sourceNodeId, sourceEdgeId);

  @override
  String toString() => 'PolePlacement($id at ($x, $z), reason: $reason)';
}
