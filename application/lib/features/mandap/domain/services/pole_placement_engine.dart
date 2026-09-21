import 'dart:math' as math;
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../value_objects/pole_placement.dart';
import 'truss_support_spacing_calculator.dart';

/// Abstract strategy interface for placing intermediate support poles on long horizontal runs.
abstract class PolePlacementStrategy {
  List<PolePlacement> calculateIntermediatePoles({
    required MandapEdge edge,
    required MandapNode startNode,
    required MandapNode endNode,
    required double maxSpanFeet,
  });
}

/// Strategy that distributes intermediate support poles at fixed 30-ft intervals,
/// with the final remainder segment using the exact remaining distance.
class FixedIntervalPoleStrategy implements PolePlacementStrategy {
  const FixedIntervalPoleStrategy();

  @override
  List<PolePlacement> calculateIntermediatePoles({
    required MandapEdge edge,
    required MandapNode startNode,
    required MandapNode endNode,
    required double maxSpanFeet,
  }) {
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final lengthFeet = math.sqrt(dx * dx + dz * dz);

    if (lengthFeet <= maxSpanFeet) {
      return const [];
    }

    final positions = const TrussSupportSpacingCalculator().calculateSupportPositions(
      lengthFeet,
      interval: maxSpanFeet,
    );

    final poles = <PolePlacement>[];
    // Exclude 0 and lengthFeet as they are the endpoints (startNode/endNode)
    for (int i = 1; i < positions.length - 1; i++) {
      final pos = positions[i];
      final t = pos / lengthFeet;
      final px = startNode.x + t * dx;
      final pz = startNode.z + t * dz;

      poles.add(
        PolePlacement(
          id: 'pole_edge_${edge.id.value}_$i',
          x: px,
          z: pz,
          reason: PoleReason.generatedMaxSpan,
          sourceEdgeId: edge.id,
        ),
      );
    }

    return List.unmodifiable(poles);
  }
}

/// Strategy that distributes intermediate support poles evenly across long edges (> maxSpanFeet).
class EvenSpacingPoleStrategy implements PolePlacementStrategy {
  const EvenSpacingPoleStrategy();

  @override
  List<PolePlacement> calculateIntermediatePoles({
    required MandapEdge edge,
    required MandapNode startNode,
    required MandapNode endNode,
    required double maxSpanFeet,
  }) {
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final lengthFeet = math.sqrt(dx * dx + dz * dz);

    if (lengthFeet <= maxSpanFeet) {
      return const [];
    }

    final int numSpans = (lengthFeet / maxSpanFeet).ceil();
    final int numIntermediatePoles = numSpans - 1;
    final poles = <PolePlacement>[];

    for (var i = 1; i <= numIntermediatePoles; i++) {
      final t = i / numSpans;
      final px = startNode.x + t * dx;
      final pz = startNode.z + t * dz;

      poles.add(
        PolePlacement(
          id: 'pole_edge_${edge.id.value}_$i',
          x: px,
          z: pz,
          reason: PoleReason.generatedMaxSpan,
          sourceEdgeId: edge.id,
        ),
      );
    }

    return List.unmodifiable(poles);
  }
}

/// Engine that computes all required vertical support poles for a [MandapLayout].
class PolePlacementEngine {
  final PolePlacementStrategy strategy;

  /// Default max unsupported span rule = 30 ft.
  final double maxSpanFeet;

  const PolePlacementEngine({
    this.strategy = const FixedIntervalPoleStrategy(),
    this.maxSpanFeet = 30.0,
  });

  /// Computes all corner poles and generated intermediate poles for [layout].
  List<PolePlacement> calculatePoles(MandapLayout layout) {
    final result = <PolePlacement>[];

    // 1. Structural nodes receive poles only if node.hasPole is true
    for (final node in layout.nodes.values) {
      if (node.type == NodeType.stage || node.type == NodeType.carpet || !node.hasPole) {
        continue;
      }
      result.add(
        PolePlacement(
          id: 'pole_node_${node.id.value}',
          x: node.x,
          z: node.z,
          reason: node.type == NodeType.pole ? PoleReason.manual : PoleReason.corner,
          sourceNodeId: node.id,
        ),
      );
    }

    // 2. Long horizontal edges receive intermediate support poles
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        // Internal members connecting to control points (e.g. center cross) do not receive ground poles
        if (startNode.type == NodeType.controlPoint || endNode.type == NodeType.controlPoint) {
          continue;
        }

        // Modular box-truss upper runs and elevated horizontal roof spans do NOT receive
        // automatic intermediate poles in the middle of bays.
        // The master specification mandates: "No unrequested internal poles ... are generated inside bays."
        final isElevatedHorizontal = (startNode.elevation > 0.1 && endNode.elevation > 0.1 && (startNode.elevation - endNode.elevation).abs() < 0.5);
        if (edge.role == TrussMemberRole.upper || isElevatedHorizontal) {
          continue;
        }

        final generated = strategy.calculateIntermediatePoles(
          edge: edge,
          startNode: startNode,
          endNode: endNode,
          maxSpanFeet: maxSpanFeet,
        );
        result.addAll(generated);
      }
    }

    return List.unmodifiable(result);
  }
}
