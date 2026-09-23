import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to split an existing truss edge into two edges with an inserted pole node.
class SplitEdgeWithPoleCommand implements MandapCommand {
  final MandapEdge edgeToRemove;
  final MandapNode newPoleNode;
  final MandapEdge edge1;
  final MandapEdge edge2;

  const SplitEdgeWithPoleCommand({
    required this.edgeToRemove,
    required this.newPoleNode,
    required this.edge1,
    required this.edge2,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    updatedNodes[newPoleNode.id] = newPoleNode;

    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    updatedEdges.remove(edgeToRemove.id);
    updatedEdges[edge1.id] = edge1;
    updatedEdges[edge2.id] = edge2;

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    updatedEdges.remove(edge1.id);
    updatedEdges.remove(edge2.id);
    updatedEdges[edgeToRemove.id] = edgeToRemove;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    updatedNodes.remove(newPoleNode.id);

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  String get description =>
      'Split truss edge ${edgeToRemove.id} with pole at (${newPoleNode.x}, ${newPoleNode.z})';
}
