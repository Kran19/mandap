import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Inserts a new [MandapEdge] between two existing nodes. Undo removes it.
class AddEdgeCommand implements MandapCommand {
  final EdgeId edgeId;
  final NodeId startNodeId;
  final NodeId endNodeId;

  const AddEdgeCommand({
    required this.edgeId,
    required this.startNodeId,
    required this.endNodeId,
  });

  @override
  MandapLayout execute(MandapLayout layout) {
    final edge = MandapEdge(
      id: edgeId,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    return layout.withEdge(edge);
  }

  @override
  MandapLayout undo(MandapLayout layout) => layout.withoutEdge(edgeId);

  @override
  String get description => 'Add edge $edgeId ($startNodeId → $endNodeId)';
}

/// Generates a unique EdgeId from the current timestamp.
EdgeId generateEdgeId() => EdgeId('e${DateTime.now().microsecondsSinceEpoch}');
