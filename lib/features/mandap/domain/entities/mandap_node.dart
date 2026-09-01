import 'package:meta/meta.dart';
import 'node_id.dart';

/// Semantic classification of a node in the Mandap structure.
enum NodeType {
  /// Corner node connecting two or more perimeter edges.
  corner,

  /// Generated intermediate support pole along long edges (> 30 ft).
  generatedSupport,

  /// End node of an open/unclosed truss run.
  openEnd,

  /// T-junction or cross-junction inside internal truss grid.
  junction,
}

/// Represents a 2D ground-plane structural node/corner/pole location.
@immutable
class MandapNode {
  final NodeId id;

  /// Ground X coordinate in feet.
  final double x;

  /// Ground Z coordinate in feet.
  final double z;

  /// Structural type of this node.
  final NodeType type;

  /// Whether this node is locked during editing operations.
  final bool isLocked;

  const MandapNode({
    required this.id,
    required this.x,
    required this.z,
    this.type = NodeType.corner,
    this.isLocked = false,
  });

  /// Returns a copy of this node with updated fields.
  MandapNode copyWith({
    NodeId? id,
    double? x,
    double? z,
    NodeType? type,
    bool? isLocked,
  }) {
    return MandapNode(
      id: id ?? this.id,
      x: x ?? this.x,
      z: z ?? this.z,
      type: type ?? this.type,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MandapNode &&
          id == other.id &&
          x == other.x &&
          z == other.z &&
          type == other.type &&
          isLocked == other.isLocked);

  @override
  int get hashCode => Object.hash(id, x, z, type, isLocked);

  @override
  String toString() => 'MandapNode($id, x: $x, z: $z, type: $type)';
}
