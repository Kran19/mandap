import 'package:vector_math/vector_math_64.dart' as v64;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Authoritative command to resize a single selected [MandapEdge] independently.
///
/// If the moving endpoint is shared with other members in the structure,
/// a new endpoint node [createdNode] is created for this edge so that
/// all other connected members remain 100% untouched.
/// If the moving endpoint is isolated (only used by this edge), it moves
/// the existing endpoint directly.
class ResizeTrussMemberCommand implements MandapCommand {
  final EdgeId edgeId;
  final NodeId anchorNodeId;
  final NodeId originalMovingNodeId;
  final MandapNode? createdNode;
  final v64.Vector3 oldPosition;
  final v64.Vector3 newPosition;
  final double oldLength;
  final double newLength;

  const ResizeTrussMemberCommand({
    required this.edgeId,
    required this.anchorNodeId,
    required this.originalMovingNodeId,
    this.createdNode,
    required this.oldPosition,
    required this.newPosition,
    required this.oldLength,
    required this.newLength,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final edge = currentLayout.getEdge(edgeId);
    if (edge == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);

    if (createdNode != null) {
      // Shared endpoint safety: insert new endpoint for this edge only
      updatedNodes[createdNode!.id] = createdNode!;
      final newEdge = edge.startNodeId == anchorNodeId
          ? edge.copyWith(endNodeId: createdNode!.id)
          : edge.copyWith(startNodeId: createdNode!.id);
      updatedEdges[edgeId] = newEdge;
    } else {
      // Isolated endpoint: directly move the single unshared node
      final node = currentLayout.getNode(originalMovingNodeId);
      if (node != null) {
        updatedNodes[originalMovingNodeId] = node.copyWith(
          x: newPosition.x,
          z: newPosition.z,
          elevation: newPosition.y,
        );
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final edge = currentLayout.getEdge(edgeId);
    if (edge == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);

    if (createdNode != null) {
      // Restore original shared node connection on this edge and remove the created node
      final restoredEdge = edge.startNodeId == anchorNodeId
          ? edge.copyWith(endNodeId: originalMovingNodeId)
          : edge.copyWith(startNodeId: originalMovingNodeId);
      updatedEdges[edgeId] = restoredEdge;
      updatedNodes.remove(createdNode!.id);
    } else {
      // Restore original position of the isolated node
      final node = currentLayout.getNode(originalMovingNodeId);
      if (node != null) {
        updatedNodes[originalMovingNodeId] = node.copyWith(
          x: oldPosition.x,
          z: oldPosition.z,
          elevation: oldPosition.y,
        );
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  String get description =>
      'Resize truss member $edgeId from ${oldLength.toStringAsFixed(1)}ft to ${newLength.toStringAsFixed(1)}ft';
}
