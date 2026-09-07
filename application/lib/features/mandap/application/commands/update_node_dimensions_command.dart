import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to update the physical dimensions, rotation, or elevation of a node.
class UpdateNodeDimensionsCommand implements MandapCommand {
  @override
  String get description => 'Updated node dimensions';

  final NodeId nodeId;
  final double? oldWidth;
  final double? oldDepth;
  final double? oldHeight;
  final double oldRotation;
  final double oldElevation;

  final double? newWidth;
  final double? newDepth;
  final double? newHeight;
  final double newRotation;
  final double newElevation;

  UpdateNodeDimensionsCommand({
    required this.nodeId,
    this.oldWidth,
    this.oldDepth,
    this.oldHeight,
    required this.oldRotation,
    required this.oldElevation,
    this.newWidth,
    this.newDepth,
    this.newHeight,
    required this.newRotation,
    required this.newElevation,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final node = currentLayout.getNode(nodeId);
    if (node == null) return currentLayout;

    final updatedNode = node.copyWith(
      width: newWidth,
      depth: newDepth,
      height: newHeight,
      rotation: newRotation,
      elevation: newElevation,
    );

    final updatedNodes = Map.of(currentLayout.nodes);
    updatedNodes[nodeId] = updatedNode;

    return MandapLayout(nodes: updatedNodes, edges: currentLayout.edges);
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final node = currentLayout.getNode(nodeId);
    if (node == null) return currentLayout;

    final revertedNode = node.copyWith(
      width: oldWidth,
      depth: oldDepth,
      height: oldHeight,
      rotation: oldRotation,
      elevation: oldElevation,
    );

    final updatedNodes = Map.of(currentLayout.nodes);
    updatedNodes[nodeId] = revertedNode;

    return MandapLayout(nodes: updatedNodes, edges: currentLayout.edges);
  }
}
