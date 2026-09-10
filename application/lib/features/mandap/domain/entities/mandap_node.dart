import 'package:meta/meta.dart';
import 'node_id.dart';

/// Semantic role / classification of a node in the Mandap structure.
enum NodeType {
  /// Corner node connecting two or more perimeter edges.
  corner,

  /// Generated intermediate support pole along long edges (> 30 ft).
  generatedSupport,

  /// Explicit perimeter pole node.
  perimeterPole,

  /// End node of an open/unclosed truss run.
  openEnd,

  /// T-junction or cross-junction inside internal truss grid.
  junction,

  /// Structural control point (e.g. center manipulation point).
  controlPoint,

  /// Generic structural endpoint.
  endpoint,

  /// A structural support pole manually placed by the user.
  pole,

  /// A raised platform area.
  stage,

  /// Floor covering area.
  carpet,
}

/// Alias for NodeType to cleanly separate semantic role from physical support.
typedef NodeRole = NodeType;

/// Physical support relationship under a node.
enum NodeSupport {
  /// Physical vertical pole under this point.
  pole,

  /// Ground anchor or structural tether.
  anchor,

  /// No physical support column underneath (floats at elevation / unsupported).
  none,
}

/// Represents a 2D ground-plane structural node, component, or area.
@immutable
class MandapNode {
  final NodeId id;

  /// Ground X coordinate in feet.
  final double x;

  /// Ground Z coordinate in feet.
  final double z;

  /// Semantic role of this node in the design.
  final NodeType type;

  /// Physical support under this node.
  final NodeSupport support;

  /// Permanent identity of the structural component this node belongs to.
  final String structureId;

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
    NodeSupport? support,
    this.structureId = 'main',
    this.isLocked = false,
    this.width,
    this.depth,
    this.height,
    this.rotation = 0.0,
    this.elevation = 0.0,
  }) : support = support ??
            ((type == NodeType.carpet || type == NodeType.stage)
                ? NodeSupport.none
                : NodeSupport.pole);

  /// Semantic role alias.
  NodeRole get role => type;

  /// Whether this node has an active vertical pole.
  bool get hasPole => support == NodeSupport.pole;

  /// Whether this node has any physical support (pole or anchor).
  bool get hasPhysicalSupport => support != NodeSupport.none;

  /// Whether this node functions as an interactive control point.
  bool get isControlPoint => type == NodeType.controlPoint;

  /// Returns a copy of this node with updated fields.
  MandapNode copyWith({
    NodeId? id,
    double? x,
    double? z,
    NodeType? type,
    NodeSupport? support,
    String? structureId,
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
      support: support ?? this.support,
      structureId: structureId ?? this.structureId,
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
          support == other.support &&
          structureId == other.structureId &&
          isLocked == other.isLocked &&
          width == other.width &&
          depth == other.depth &&
          height == other.height &&
          rotation == other.rotation &&
          elevation == other.elevation);

  @override
  int get hashCode => Object.hash(
        id,
        x,
        z,
        type,
        support,
        structureId,
        isLocked,
        width,
        depth,
        height,
        rotation,
        elevation,
      );

  @override
  String toString() =>
      'MandapNode($id at ($x, $z), role: $type, support: $support, struct: $structureId)';
}
