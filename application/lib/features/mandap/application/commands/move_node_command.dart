import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to translate a single [MandapNode] to a new ground position.
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

    return MandapLayout(nodes: updatedNodes, edges: layout.edges);
  }

  @override
  String get description => 'Move node $nodeId to ($newX, $newZ)';
}
