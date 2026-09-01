import 'package:meta/meta.dart';
import '../../../../core/geometry/length.dart';
import 'edge_id.dart';
import 'mandap_edge.dart';
import 'mandap_node.dart';
import 'node_id.dart';

/// Represents a complete Mandap layout graph consisting of nodes and connecting edges.
@immutable
class MandapLayout {
  final Map<NodeId, MandapNode> nodes;
  final Map<EdgeId, MandapEdge> edges;

  const MandapLayout({required this.nodes, required this.edges});

  /// Factory constructor for a standard rectangular Mandap preset.
  ///
  /// N1(0,0) ─────────── N2(width,0)
  ///   │                      │
  ///   │                      │
  /// N4(0,length) ────── N3(width,length)
  factory MandapLayout.rectangle({
    required Length width,
    required Length length,
  }) {
    final n1Id = const NodeId('n1');
    final n2Id = const NodeId('n2');
    final n3Id = const NodeId('n3');
    final n4Id = const NodeId('n4');

    final nodes = <NodeId, MandapNode>{
      n1Id: MandapNode(id: n1Id, x: 0.0, z: 0.0, type: NodeType.corner),
      n2Id: MandapNode(id: n2Id, x: width.feet, z: 0.0, type: NodeType.corner),
      n3Id: MandapNode(
        id: n3Id,
        x: width.feet,
        z: length.feet,
        type: NodeType.corner,
      ),
      n4Id: MandapNode(id: n4Id, x: 0.0, z: length.feet, type: NodeType.corner),
    };

    final e1Id = const EdgeId('e1');
    final e2Id = const EdgeId('e2');
    final e3Id = const EdgeId('e3');
    final e4Id = const EdgeId('e4');

    final edges = <EdgeId, MandapEdge>{
      e1Id: MandapEdge(id: e1Id, startNodeId: n1Id, endNodeId: n2Id),
      e2Id: MandapEdge(id: e2Id, startNodeId: n2Id, endNodeId: n3Id),
      e3Id: MandapEdge(id: e3Id, startNodeId: n3Id, endNodeId: n4Id),
      e4Id: MandapEdge(id: e4Id, startNodeId: n4Id, endNodeId: n1Id),
    };

    return MandapLayout(nodes: nodes, edges: edges);
  }

  /// Gets a node by ID.
  MandapNode? getNode(NodeId id) => nodes[id];

  /// Gets an edge by ID.
  MandapEdge? getEdge(EdgeId id) => edges[id];

  /// Returns the computed physical geometric length for a given edge.
  ///
  /// If nodes exist, physical geometric length derived from coordinates is used.
  /// Otherwise, falls back to requestedLength if set.
  Length getEdgeLength(MandapEdge edge) {
    final startNode = nodes[edge.startNodeId];
    final endNode = nodes[edge.endNodeId];

    if (startNode != null && endNode != null) {
      return edge.calculateGeometricLength(startNode, endNode);
    }
    if (edge.requestedLength != null) {
      return edge.requestedLength!;
    }
    throw StateError(
      'Edge ${edge.id} has missing endpoint nodes and no requested length',
    );
  }

  /// Validates structural layout graph integrity.
  List<String> validate() {
    final issues = <String>[];

    if (nodes.isEmpty) {
      issues.add('Layout contains no nodes');
    }
    if (edges.isEmpty) {
      issues.add('Layout contains no edges');
    }

    for (final edge in edges.values) {
      final startNode = nodes[edge.startNodeId];
      final endNode = nodes[edge.endNodeId];

      if (startNode == null) {
        issues.add(
          'Edge ${edge.id} references missing start node ${edge.startNodeId}',
        );
      }
      if (endNode == null) {
        issues.add(
          'Edge ${edge.id} references missing end node ${edge.endNodeId}',
        );
      }

      if (startNode != null && endNode != null) {
        if (startNode.id == endNode.id) {
          issues.add('Edge ${edge.id} connects node ${startNode.id} to itself');
        } else {
          try {
            final len = edge.calculateGeometricLength(startNode, endNode);
            if (len.isZero) {
              issues.add('Edge ${edge.id} has zero length');
            }
          } on ArgumentError catch (e) {
            issues.add(
              'Edge ${edge.id} length is not a valid 0.5 ft increment: $e',
            );
          }
        }
      }
    }

    // Phase 4: validate for isolated nodes (not referenced by any edge)
    final referencedNodeIds = <NodeId>{};
    for (final edge in edges.values) {
      referencedNodeIds.add(edge.startNodeId);
      referencedNodeIds.add(edge.endNodeId);
    }
    for (final nodeId in nodes.keys) {
      if (!referencedNodeIds.contains(nodeId)) {
        issues.add('Node $nodeId is isolated (not connected to any edge)');
      }
    }

    // Phase 4: validate graph connectivity (detect disconnected components)
    if (nodes.isNotEmpty && edges.isNotEmpty) {
      final adjacency = <NodeId, Set<NodeId>>{};
      for (final n in nodes.keys) {
        adjacency[n] = {};
      }
      for (final e in edges.values) {
        if (nodes.containsKey(e.startNodeId) &&
            nodes.containsKey(e.endNodeId)) {
          adjacency[e.startNodeId]?.add(e.endNodeId);
          adjacency[e.endNodeId]?.add(e.startNodeId);
        }
      }

      final visited = <NodeId>{};
      final queue = <NodeId>[nodes.keys.first];
      visited.add(nodes.keys.first);

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        for (final neighbor in adjacency[current] ?? <NodeId>{}) {
          if (visited.add(neighbor)) {
            queue.add(neighbor);
          }
        }
      }

      if (visited.length < nodes.length) {
        issues.add(
          'Layout graph is disconnected (${visited.length} of ${nodes.length} nodes connected)',
        );
      }
    }

    // Phase 4: validate crossing edges (detect intersecting edge segments)
    final edgeList = edges.values.toList();
    for (var i = 0; i < edgeList.length; i++) {
      for (var j = i + 1; j < edgeList.length; j++) {
        final e1 = edgeList[i];
        final e2 = edgeList[j];

        // Skip adjacent edges that share a node
        if (e1.startNodeId == e2.startNodeId ||
            e1.startNodeId == e2.endNodeId ||
            e1.endNodeId == e2.startNodeId ||
            e1.endNodeId == e2.endNodeId) {
          continue;
        }

        final n1a = nodes[e1.startNodeId];
        final n1b = nodes[e1.endNodeId];
        final n2a = nodes[e2.startNodeId];
        final n2b = nodes[e2.endNodeId];

        if (n1a != null && n1b != null && n2a != null && n2b != null) {
          if (_segmentsIntersect(n1a, n1b, n2a, n2b)) {
            issues.add(
              'Edges ${e1.id} and ${e2.id} cross each other in 2D space',
            );
          }
        }
      }
    }

    return issues;
  }

  static bool _segmentsIntersect(
    MandapNode p1,
    MandapNode q1,
    MandapNode p2,
    MandapNode q2,
  ) {
    double ccw(
      double ax,
      double az,
      double bx,
      double bz,
      double cx,
      double cz,
    ) {
      return (cz - az) * (bx - ax) - (cx - ax) * (bz - az);
    }

    final o1 = ccw(p1.x, p1.z, q1.x, q1.z, p2.x, p2.z);
    final o2 = ccw(p1.x, p1.z, q1.x, q1.z, q2.x, q2.z);
    final o3 = ccw(p2.x, p2.z, q2.x, q2.z, p1.x, p1.z);
    final o4 = ccw(p2.x, p2.z, q2.x, q2.z, q1.x, q1.z);

    return (o1 * o2 < 0) && (o3 * o4 < 0);
  }

  // ── Immutable mutation helpers ──────────────────────────────────────────

  /// Returns a new layout with [node] inserted or replaced.
  MandapLayout withNode(MandapNode node) {
    final updated = Map<NodeId, MandapNode>.from(nodes)..[node.id] = node;
    return MandapLayout(nodes: updated, edges: edges);
  }

  /// Returns a new layout with [edge] inserted or replaced.
  MandapLayout withEdge(MandapEdge edge) {
    final updated = Map<EdgeId, MandapEdge>.from(edges)..[edge.id] = edge;
    return MandapLayout(nodes: nodes, edges: updated);
  }

  /// Returns a new layout without the node identified by [nodeId].
  /// Does NOT automatically remove connected edges — callers must handle that.
  MandapLayout withoutNode(NodeId nodeId) {
    final updated = Map<NodeId, MandapNode>.from(nodes)..remove(nodeId);
    return MandapLayout(nodes: updated, edges: edges);
  }

  /// Returns a new layout without the edge identified by [edgeId].
  MandapLayout withoutEdge(EdgeId edgeId) {
    final updated = Map<EdgeId, MandapEdge>.from(edges)..remove(edgeId);
    return MandapLayout(nodes: nodes, edges: updated);
  }

  /// Returns a new layout with all edges referencing [nodeId] removed,
  /// then the node itself removed. Safe composite operation.
  MandapLayout withoutNodeAndConnectedEdges(NodeId nodeId) {
    final filteredEdges = Map<EdgeId, MandapEdge>.from(edges)
      ..removeWhere(
        (_, edge) => edge.startNodeId == nodeId || edge.endNodeId == nodeId,
      );
    final filteredNodes = Map<NodeId, MandapNode>.from(nodes)..remove(nodeId);
    return MandapLayout(nodes: filteredNodes, edges: filteredEdges);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MandapLayout &&
          _mapsEqual(nodes, other.nodes) &&
          _mapsEqual(edges, other.edges));

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(nodes.entries), Object.hashAll(edges.entries));

  static bool _mapsEqual<K, V>(Map<K, V> m1, Map<K, V> m2) {
    if (m1.length != m2.length) return false;
    for (final key in m1.keys) {
      if (!m2.containsKey(key) || m1[key] != m2[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'MandapLayout(${nodes.length} nodes, ${edges.length} edges)';
}
