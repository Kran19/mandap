import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Command to adjust the interactive center structural control point.
///
/// Modifies the center apex elevation (clamped to valid structural bounds)
/// and/or translates the center apex position in the X/Z plane.
/// Connected cross members automatically update with the center node.
class AdjustCenterControlCommand implements MandapCommand {
  final NodeId centerNodeId;
  final double oldX;
  final double oldZ;
  final double oldElevation;
  final double newX;
  final double newZ;
  final double newElevation;
  final double mainTrussElevation;

  const AdjustCenterControlCommand({
    required this.centerNodeId,
    required this.oldX,
    required this.oldZ,
    required this.oldElevation,
    required this.newX,
    required this.newZ,
    required this.newElevation,
    this.mainTrussElevation = 20.0,
  });

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final node = currentLayout.getNode(centerNodeId);
    if (node == null) return currentLayout;

    // Enforce structural limits:
    // Minimum: flat with main truss (mainTrussElevation)
    // Maximum: peaked roof (+10 ft above main truss)
    final clampedElev = newElevation.clamp(
      mainTrussElevation,
      mainTrussElevation + 10.0,
    );

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    updatedNodes[centerNodeId] = node.copyWith(
      x: newX,
      z: newZ,
      elevation: clampedElev,
      height: clampedElev,
    );

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final node = currentLayout.getNode(centerNodeId);
    if (node == null) return currentLayout;

    final updatedNodes = Map<NodeId, MandapNode>.from(currentLayout.nodes);
    updatedNodes[centerNodeId] = node.copyWith(
      x: oldX,
      z: oldZ,
      elevation: oldElevation,
      height: oldElevation,
    );

    return MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
  }

  @override
  String get description =>
      'Adjust center control $centerNodeId to ($newX, $newZ, elev: $newElevation ft)';
}
