import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command supporting execution and undo of edge resizing operations while maintaining orthogonality.
class ResizeEdgeCommand implements MandapCommand {
  final EdgeId edgeId;
  final NodeId movingNodeId;
  final double oldX;
  final double oldZ;
  final double newX;
  final double newZ;

  const ResizeEdgeCommand({
    required this.edgeId,
    required this.movingNodeId,
    required this.oldX,
    required this.oldZ,
    required this.newX,
    required this.newZ,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    return _applyPosition(currentLayout, newX, newZ, oldX, oldZ);
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    return _applyPosition(currentLayout, oldX, oldZ, newX, newZ);
  }

  MandapLayout _applyPosition(
    MandapLayout layout,
    double targetX,
    double targetZ,
    double fromX,
    double fromZ,
  ) {
    final currentNode = layout.getNode(movingNodeId);
    if (currentNode == null) return layout;

    final updatedNodes = Map<NodeId, MandapNode>.from(layout.nodes);
    updatedNodes[movingNodeId] = currentNode.copyWith(x: targetX, z: targetZ);

    // Shift aligned nodes if part of rectangular topology to preserve orthogonality
    final dx = targetX - fromX;
    final dz = targetZ - fromZ;

    for (final node in layout.nodes.values) {
      if (node.id != movingNodeId) {
        if ((node.x - fromX).abs() < 1e-4 && dx.abs() > 1e-4) {
          updatedNodes[node.id] = node.copyWith(x: node.x + dx);
        }
        if ((node.z - fromZ).abs() < 1e-4 && dz.abs() > 1e-4) {
          updatedNodes[node.id] = node.copyWith(z: node.z + dz);
        }
      }
    }

    return MandapLayout(nodes: updatedNodes, edges: layout.edges);
  }

  @override
  String get description => 'Resize edge $edgeId';
}
