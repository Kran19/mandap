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
  /// A structural support pole manually placed by the user.
  pole,

  /// A raised platform area.
  stage,

  /// Floor covering area.
  carpet,
}

/// Represents a 2D ground-plane structural node, component, or area.
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

  /// Optional X-axis width in feet (e.g., for stage/carpet).
  final double? width;

  /// Optional Z-axis depth in feet (e.g., for stage/carpet).
  final double? depth;

  /// Optional Y-axis height in feet (e.g., for pole/stage thickness).
  final double? height;

  /// Y-axis rotation in radians (0.0 = unrotated).
  final double rotation;

  /// Y-axis elevation from ground (0.0) in feet.
  final double elevation;

  const MandapNode({
    required this.id,
    required this.x,
    required this.z,
    this.type = NodeType.corner,
    this.isLocked = false,
    this.width,
    this.depth,
    this.height,
    this.rotation = 0.0,
    this.elevation = 0.0,
  });

  /// Returns a copy of this node with updated fields.
  MandapNode copyWith({
    NodeId? id,
    double? x,
    double? z,
    NodeType? type,
    bool? isLocked,
    double? width,
    double? depth,
    double? height,
    double? rotation,
    double? elevation,
  }) {
    return MandapNode(
      id: id ?? this.id,
      x: x ?? this.x,
      z: z ?? this.z,
      type: type ?? this.type,
      isLocked: isLocked ?? this.isLocked,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      elevation: elevation ?? this.elevation,
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
          isLocked == other.isLocked &&
          width == other.width &&
          depth == other.depth &&
          height == other.height &&
          rotation == other.rotation &&
          elevation == other.elevation);

  @override
  int get hashCode => Object.hash(id, x, z, type, isLocked, width, depth, height, rotation, elevation);

  @override
  String toString() => 'MandapNode($id, x: $x, z: $z, type: $type)';
}
