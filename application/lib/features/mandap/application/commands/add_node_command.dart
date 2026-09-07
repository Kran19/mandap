import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Inserts a new [MandapNode] into the layout. Undo removes it.
class AddNodeCommand implements MandapCommand {
  final MandapNode node;

  const AddNodeCommand({required this.node});

  @override
  MandapLayout execute(MandapLayout layout) => layout.withNode(node);

  @override
  MandapLayout undo(MandapLayout layout) => layout.withoutNode(node.id);

  @override
  String get description => 'Add node ${node.id}';
}

int _nodeCounter = 0;

/// Convenience factory: creates a node with a unique timestamped ID.
MandapNode createNode({
  required double x,
  required double z,
  NodeType type = NodeType.corner,
}) {
  _nodeCounter++;
  final id = NodeId('n${DateTime.now().microsecondsSinceEpoch}_$_nodeCounter');
  return MandapNode(id: id, x: x, z: z, type: type);
}
