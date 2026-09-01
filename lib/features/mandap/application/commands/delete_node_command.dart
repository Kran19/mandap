import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Removes a [MandapNode] and all edges connected to it. Undo re-inserts all.
class DeleteNodeCommand implements MandapCommand {
  final NodeId nodeId;

  /// Snapshot of the node at deletion time.
  final MandapNode nodeSnapshot;

  /// Snapshots of all connected edges removed as part of this operation.
  final List<MandapEdge> _connectedEdgeSnapshots;

  DeleteNodeCommand({
    required this.nodeId,
    required this.nodeSnapshot,
    required List<MandapEdge> connectedEdgeSnapshots,
  }) : _connectedEdgeSnapshots = List.unmodifiable(connectedEdgeSnapshots);

  @override
  MandapLayout execute(MandapLayout layout) =>
      layout.withoutNodeAndConnectedEdges(nodeId);

  @override
  MandapLayout undo(MandapLayout layout) {
    // Re-insert node first, then all its edges.
    var restored = layout.withNode(nodeSnapshot);
    for (final edge in _connectedEdgeSnapshots) {
      restored = restored.withEdge(edge);
    }
    return restored;
  }

  @override
  String get description =>
      'Delete node $nodeId (${_connectedEdgeSnapshots.length} edges removed)';
}
