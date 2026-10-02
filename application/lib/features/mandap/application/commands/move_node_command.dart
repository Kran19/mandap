import 'dart:math' as math;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to translate a single [MandapNode] to a new ground position
/// while preserving parallel side symmetry across perimeter walls.
class MoveNodeCommand implements MandapCommand {
  final NodeId nodeId;
  final double oldX;
  final double oldZ;
  final double newX;
  final double newZ;

  const MoveNodeCommand({
    required this.nodeId,
    required this.oldX,
    required this.oldZ,
    required this.newX,
    required this.newZ,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    return _setPosition(currentLayout, newX, newZ);
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    return _setPosition(currentLayout, oldX, oldZ);
  }

  MandapLayout _setPosition(MandapLayout layout, double x, double z) {
    final node = layout.getNode(nodeId);
    if (node == null) return layout;

    final updatedNodes = Map<NodeId, MandapNode>.from(layout.nodes);
    updatedNodes[nodeId] = node.copyWith(x: x, z: z);

    // Calculate layout bounds (minX, maxX, minZ, maxZ)
    double minX = 0, maxX = 100, minZ = 0, maxZ = 100;
    if (layout.nodes.isNotEmpty) {
      minX = layout.nodes.values.map((n) => n.x).reduce(math.min);
      maxX = layout.nodes.values.map((n) => n.x).reduce(math.max);
      minZ = layout.nodes.values.map((n) => n.z).reduce(math.min);
      maxZ = layout.nodes.values.map((n) => n.z).reduce(math.max);
    }

    // Parallel edge/node synchronization across opposite perimeter walls
    if ((oldX - minX).abs() < 1.5 && (x - minX).abs() < 1.5 && node.type != NodeType.corner) {
      // Node is moving along West wall (changing Z) -> Sync matching node on East wall
      for (final n in layout.nodes.values) {
        if (n.id != nodeId && (n.x - maxX).abs() < 1.5 && (n.z - oldZ).abs() < 1.5 && n.type != NodeType.corner) {
          updatedNodes[n.id] = n.copyWith(z: z);
        }
      }
    } else if ((oldX - maxX).abs() < 1.5 && (x - maxX).abs() < 1.5 && node.type != NodeType.corner) {
      // Node is moving along East wall (changing Z) -> Sync matching node on West wall
      for (final n in layout.nodes.values) {
        if (n.id != nodeId && (n.x - minX).abs() < 1.5 && (n.z - oldZ).abs() < 1.5 && n.type != NodeType.corner) {
          updatedNodes[n.id] = n.copyWith(z: z);
        }
      }
    } else if ((oldZ - minZ).abs() < 1.5 && (z - minZ).abs() < 1.5 && node.type != NodeType.corner) {
      // Node is moving along North wall (changing X) -> Sync matching node on South wall
      for (final n in layout.nodes.values) {
        if (n.id != nodeId && (n.z - maxZ).abs() < 1.5 && (n.x - oldX).abs() < 1.5 && n.type != NodeType.corner) {
          updatedNodes[n.id] = n.copyWith(x: x);
        }
      }
    } else if ((oldZ - maxZ).abs() < 1.5 && (z - maxZ).abs() < 1.5 && node.type != NodeType.corner) {
      // Node is moving along South wall (changing X) -> Sync matching node on North wall
      for (final n in layout.nodes.values) {
        if (n.id != nodeId && (n.z - minZ).abs() < 1.5 && (n.x - oldX).abs() < 1.5 && n.type != NodeType.corner) {
          updatedNodes[n.id] = n.copyWith(x: x);
        }
      }
    }

    final updatedEdges = Map<EdgeId, MandapEdge>.from(layout.edges);

    _resortPerimeterEdges(
      nodes: updatedNodes,
      edges: updatedEdges,
      minX: minX,
      maxX: maxX,
      minZ: minZ,
      maxZ: maxZ,
    );

    return MandapLayout(nodes: Map.unmodifiable(updatedNodes), edges: Map.unmodifiable(updatedEdges));
  }

  void _resortPerimeterEdges({
    required Map<NodeId, MandapNode> nodes,
    required Map<EdgeId, MandapEdge> edges,
    required double minX,
    required double maxX,
    required double minZ,
    required double maxZ,
  }) {
    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.z - minZ).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(z: minZ),
      compare: (a, b) => a.x.compareTo(b.x),
    );

    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.z - maxZ).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(z: maxZ),
      compare: (a, b) => a.x.compareTo(b.x),
    );

    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.x - minX).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(x: minX),
      compare: (a, b) => a.z.compareTo(b.z),
    );

    _reorderWallNodesAndEdges(
      nodes: nodes,
      edges: edges,
      isOnWall: (n) => (n.x - maxX).abs() <= 1.0 && n.type != NodeType.stage && n.type != NodeType.carpet,
      clampToWall: (n) => n.copyWith(x: maxX),
      compare: (a, b) => a.z.compareTo(b.z),
    );
  }

  void _reorderWallNodesAndEdges({
    required Map<NodeId, MandapNode> nodes,
    required Map<EdgeId, MandapEdge> edges,
    required bool Function(MandapNode n) isOnWall,
    required MandapNode Function(MandapNode n) clampToWall,
    required int Function(MandapNode a, MandapNode b) compare,
  }) {
    final wallNodes = <MandapNode>[];
    for (final entry in nodes.entries) {
      if (isOnWall(entry.value)) {
        final clamped = clampToWall(entry.value);
        nodes[entry.key] = clamped;
        wallNodes.add(clamped);
      }
    }

    if (wallNodes.length < 2) return;

    wallNodes.sort(compare);

    final wallNodeIds = wallNodes.map((n) => n.id).toSet();
    final wallEdgeKeys = <EdgeId>[];
    for (final entry in edges.entries) {
      if (wallNodeIds.contains(entry.value.startNodeId) &&
          wallNodeIds.contains(entry.value.endNodeId)) {
        wallEdgeKeys.add(entry.key);
      }
    }

    if (wallEdgeKeys.length == wallNodes.length - 1) {
      for (int i = 0; i < wallNodes.length - 1; i++) {
        final edgeId = wallEdgeKeys[i];
        final existingEdge = edges[edgeId]!;
        edges[edgeId] = existingEdge.copyWith(
          startNodeId: wallNodes[i].id,
          endNodeId: wallNodes[i + 1].id,
        );
      }
    } else if (wallEdgeKeys.isNotEmpty) {
      for (int i = 0; i < math.min(wallEdgeKeys.length, wallNodes.length - 1); i++) {
        final edgeId = wallEdgeKeys[i];
        final existingEdge = edges[edgeId]!;
        edges[edgeId] = existingEdge.copyWith(
          startNodeId: wallNodes[i].id,
          endNodeId: wallNodes[i + 1].id,
        );
      }
    }
  }

  @override
  String get description => 'Move node $nodeId to ($newX, $newZ)';
}
