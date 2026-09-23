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
  final NodeId movingNodeId;
  final NodeId? parallelMovingNodeId;
  final v64.Vector3 oldPosition;
  final v64.Vector3 newPosition;
  final v64.Vector3? oldParallelPosition;
  final v64.Vector3? newParallelPosition;
  final Map<NodeId, v64.Vector3>? additionalOldPositions;
  final Map<NodeId, v64.Vector3>? additionalNewPositions;
  final double oldLength;
  final double newLength;

  const ResizeTrussMemberCommand({
    required this.edgeId,
    required this.anchorNodeId,
    required this.movingNodeId,
    this.parallelMovingNodeId,
    required this.oldPosition,
    required this.newPosition,
    this.oldParallelPosition,
    this.newParallelPosition,
    this.additionalOldPositions,
    this.additionalNewPositions,
    required this.oldLength,
    required this.newLength,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);

    // 1. Directly move the shared intermediate support node
    final node = currentLayout.getNode(movingNodeId);
    if (node != null) {
      updatedNodes[movingNodeId] = node.copyWith(
        x: newPosition.x,
        z: newPosition.z,
        elevation: newPosition.y,
      );
    }

    // 2. Synchronously move corresponding node on parallel wall
    if (parallelMovingNodeId != null && newParallelPosition != null) {
      final pNode = currentLayout.getNode(parallelMovingNodeId!);
      if (pNode != null) {
        updatedNodes[parallelMovingNodeId!] = pNode.copyWith(
          x: newParallelPosition!.x,
          z: newParallelPosition!.z,
          elevation: newParallelPosition!.y,
        );
      }
    }

    // 3. Move any other collinear wall nodes that must stay aligned
    if (additionalNewPositions != null) {
      for (final entry in additionalNewPositions!.entries) {
        final aNode = currentLayout.getNode(entry.key);
        if (aNode != null) {
          updatedNodes[entry.key] = aNode.copyWith(
            x: entry.value.x,
            z: entry.value.z,
            elevation: entry.value.y,
          );
        }
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);

    final node = currentLayout.getNode(movingNodeId);
    if (node != null) {
      updatedNodes[movingNodeId] = node.copyWith(
        x: oldPosition.x,
        z: oldPosition.z,
        elevation: oldPosition.y,
      );
    }

    if (parallelMovingNodeId != null && oldParallelPosition != null) {
      final pNode = currentLayout.getNode(parallelMovingNodeId!);
      if (pNode != null) {
        updatedNodes[parallelMovingNodeId!] = pNode.copyWith(
          x: oldParallelPosition!.x,
          z: oldParallelPosition!.z,
          elevation: oldParallelPosition!.y,
        );
      }
    }

    if (additionalOldPositions != null) {
      for (final entry in additionalOldPositions!.entries) {
        final aNode = currentLayout.getNode(entry.key);
        if (aNode != null) {
          updatedNodes[entry.key] = aNode.copyWith(
            x: entry.value.x,
            z: entry.value.z,
            elevation: entry.value.y,
          );
        }
      }
    }

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  @override
  String get description =>
      'Resize truss member $edgeId from ${oldLength.toStringAsFixed(1)}ft to ${newLength.toStringAsFixed(1)}ft (synchronized with parallel wall)';
}
