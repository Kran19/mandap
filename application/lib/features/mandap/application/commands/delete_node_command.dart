import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Removes a [MandapNode] and all edges connected to it, merging collinear edges if applicable.
/// Also synchronizes removal and merging on opposing parallel walls.
class DeleteNodeCommand implements MandapCommand {
  final NodeId nodeId;

  /// Snapshot of the node at deletion time.
  final MandapNode nodeSnapshot;

  /// Snapshots of all connected edges removed as part of this operation.
  final List<MandapEdge> _connectedEdgeSnapshots;

  /// Single continuous edge that bridges the gap after removing an intermediate node.
  final MandapEdge? mergedEdge;

  /// Optional corresponding parallel node removed synchronously.
  final NodeId? parallelNodeId;
  final MandapNode? parallelNodeSnapshot;
  final List<MandapEdge>? _parallelConnectedEdgeSnapshots;
  final MandapEdge? parallelMergedEdge;

  DeleteNodeCommand({
    required this.nodeId,
    required this.nodeSnapshot,
    required List<MandapEdge> connectedEdgeSnapshots,
    this.mergedEdge,
    this.parallelNodeId,
    this.parallelNodeSnapshot,
    List<MandapEdge>? parallelConnectedEdgeSnapshots,
    this.parallelMergedEdge,
  })  : _connectedEdgeSnapshots = List.unmodifiable(connectedEdgeSnapshots),
        _parallelConnectedEdgeSnapshots = parallelConnectedEdgeSnapshots != null
            ? List.unmodifiable(parallelConnectedEdgeSnapshots)
            : null;

  @override
  MandapLayout execute(MandapLayout layout) {
    var updated = layout.withoutNodeAndConnectedEdges(nodeId);
    if (mergedEdge != null) {
      updated = updated.withEdge(mergedEdge!);
    }

    if (parallelNodeId != null) {
      updated = updated.withoutNodeAndConnectedEdges(parallelNodeId!);
      if (parallelMergedEdge != null) {
        updated = updated.withEdge(parallelMergedEdge!);
      }
    }
    return updated;
  }

  @override
  MandapLayout undo(MandapLayout layout) {
    var restored = layout;
    if (mergedEdge != null) {
      restored = restored.withoutEdge(mergedEdge!.id);
    }
    if (parallelMergedEdge != null && parallelMergedEdge != null) {
      restored = restored.withoutEdge(parallelMergedEdge!.id);
    }

    restored = restored.withNode(nodeSnapshot);
    for (final edge in _connectedEdgeSnapshots) {
      restored = restored.withEdge(edge);
    }

    if (parallelNodeSnapshot != null && _parallelConnectedEdgeSnapshots != null) {
      restored = restored.withNode(parallelNodeSnapshot!);
      for (final edge in _parallelConnectedEdgeSnapshots!) {
        restored = restored.withEdge(edge);
      }
    }

    return restored;
  }

  @override
  String get description =>
      'Delete node $nodeId (${_connectedEdgeSnapshots.length} edges removed, merged=${mergedEdge != null})';
}
