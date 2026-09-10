import 'dart:math' as math;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Target side of the main structure to attach an external entrance / structure.
enum EntranceSide {
  /// Side A: North / Back edge (Z = Depth, extends +Z)
  northA,

  /// Side B: East / Right edge (X = Width, extends +X)
  eastB,

  /// Side C: South / Front edge (Z = 0, extends -Z)
  southC,

  /// Side D: West / Left edge (X = 0, extends -X)
  westD,
}

/// Command to attach a separate external structure (such as an entrance gate)
/// to a chosen side of the main structure using the deterministic coordinate contract.
class AddExternalStructureCommand implements MandapCommand {
  final String structureId;
  final EntranceSide side;
  final double width;
  final double projection;
  final double offset;
  final double height;

  final List<NodeId> _generatedNodeIds = [];
  final List<EdgeId> _generatedEdgeIds = [];

  AddExternalStructureCommand({
    required this.structureId,
    required this.side,
    required this.width,
    required this.projection,
    required this.offset,
    this.height = 20.0,
  });

  @override
  MandapLayout execute(MandapLayout layout) {
    _generatedNodeIds.clear();
    _generatedEdgeIds.clear();

    // Determine bounding box of main structure
    double minX = 0.0, maxX = 100.0, minZ = 0.0, maxZ = 100.0;
    if (layout.nodes.isNotEmpty) {
      final mainNodes = layout.nodes.values.where((n) => n.structureId == 'main');
      final pool = mainNodes.isNotEmpty ? mainNodes : layout.nodes.values;
      minX = pool.map((n) => n.x).reduce(math.min);
      maxX = pool.map((n) => n.x).reduce(math.max);
      minZ = pool.map((n) => n.z).reduce(math.min);
      maxZ = pool.map((n) => n.z).reduce(math.max);
    }

    double a1X = 0, a1Z = 0, a2X = 0, a2Z = 0;
    double o1X = 0, o1Z = 0, o2X = 0, o2Z = 0;

    switch (side) {
      case EntranceSide.northA:
        // Main boundary Z = maxZ; extends into +Z
        a1X = minX + offset;
        a1Z = maxZ;
        a2X = minX + offset + width;
        a2Z = maxZ;
        o1X = a1X;
        o1Z = maxZ + projection;
        o2X = a2X;
        o2Z = maxZ + projection;

      case EntranceSide.eastB:
        // Main boundary X = maxX; extends into +X
        a1X = maxX;
        a1Z = minZ + offset;
        a2X = maxX;
        a2Z = minZ + offset + width;
        o1X = maxX + projection;
        o1Z = a1Z;
        o2X = maxX + projection;
        o2Z = a2Z;

      case EntranceSide.southC:
        // Main boundary Z = minZ; extends into -Z
        a1X = minX + offset;
        a1Z = minZ;
        a2X = minX + offset + width;
        a2Z = minZ;
        o1X = a1X;
        o1Z = minZ - projection;
        o2X = a2X;
        o2Z = minZ - projection;

      case EntranceSide.westD:
        // Main boundary X = minX; extends into -X
        a1X = minX;
        a1Z = minZ + offset;
        a2X = minX;
        a2Z = minZ + offset + width;
        o1X = minX - projection;
        o1Z = a1Z;
        o2X = minX - projection;
        o2Z = a2Z;
    }

    var current = layout;

    // Helper to find existing node at coordinate or create a new node
    MandapNode findOrCreateNode(double x, double z, NodeType role, NodeSupport support) {
      for (final existing in current.nodes.values) {
        if ((existing.x - x).abs() < 0.01 && (existing.z - z).abs() < 0.01) {
          return existing;
        }
      }
      final ts = DateTime.now().microsecondsSinceEpoch % 100000;
      final newId = NodeId('ext_${structureId}_${_generatedNodeIds.length}_$ts');
      final node = MandapNode(
        id: newId,
        x: x,
        z: z,
        type: role,
        support: support,
        height: height,
        elevation: height,
        structureId: structureId,
      );
      _generatedNodeIds.add(newId);
      current = current.withNode(node);
      return node;
    }

    final nAttach1 = findOrCreateNode(a1X, a1Z, NodeType.junction, NodeSupport.pole);
    final nAttach2 = findOrCreateNode(a2X, a2Z, NodeType.junction, NodeSupport.pole);
    final nOuter1 = findOrCreateNode(o1X, o1Z, NodeType.corner, NodeSupport.pole);
    final nOuter2 = findOrCreateNode(o2X, o2Z, NodeType.corner, NodeSupport.pole);

    void addEdge(NodeId start, NodeId end) {
      final ts = DateTime.now().microsecondsSinceEpoch % 100000;
      final eId = EdgeId('ext_edge_${structureId}_${_generatedEdgeIds.length}_$ts');
      _generatedEdgeIds.add(eId);
      current = current.withEdge(MandapEdge(
        id: eId,
        startNodeId: start,
        endNodeId: end,
        profile: EdgeProfile.box,
      ));
    }

    // Outer edge connecting the two outer corners
    addEdge(nOuter1.id, nOuter2.id);

    // Left projection edge
    addEdge(nAttach1.id, nOuter1.id);

    // Right projection edge
    addEdge(nAttach2.id, nOuter2.id);

    return current;
  }

  @override
  MandapLayout undo(MandapLayout layout) {
    var current = layout;
    for (final eId in _generatedEdgeIds) {
      current = current.withoutEdge(eId);
    }
    for (final nId in _generatedNodeIds) {
      current = current.withoutNode(nId);
    }
    return current;
  }

  @override
  String get description =>
      'Add Entrance $structureId (${width.toInt()}×${projection.toInt()} ft on Side ${side.name})';
}
