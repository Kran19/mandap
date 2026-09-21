import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Atomic command to create a single new truss member drawn by Pen.
///
/// Encapsulates creation of the new member edge along with its endpoint
/// node and (if drawn from empty space) its start node.
///
/// Undo atomically removes the new edge and its created nodes, cleanly
/// restoring the prior layout without touching any existing members.
class CreateTrussMemberCommand implements MandapCommand {
  final MandapNode? newStartNode;
  final MandapNode? newEndNode;
  final MandapEdge newEdge;

  const CreateTrussMemberCommand({
    this.newStartNode,
    this.newEndNode,
    required this.newEdge,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    if (newStartNode != null) {
      updatedNodes[newStartNode!.id] = newStartNode!;
    }
    if (newEndNode != null) {
      updatedNodes[newEndNode!.id] = newEndNode!;
    }

    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    updatedEdges[newEdge.id] = newEdge;

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    updatedEdges.remove(newEdge.id);

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    if (newEndNode != null) {
      updatedNodes.remove(newEndNode!.id);
    }
    if (newStartNode != null) {
      updatedNodes.remove(newStartNode!.id);
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  String get description =>
      'Create new truss member ${newEdge.id} (${newEdge.startNodeId} → ${newEdge.endNodeId})';
}
