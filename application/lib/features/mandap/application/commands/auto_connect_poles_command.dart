import 'dart:math' as math;
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import 'mandap_command.dart';

/// Command to automatically connect 4 poles in perimeter order with truss edges.
class AutoConnectPolesCommand implements MandapCommand {
  final List<MandapEdge> newEdges;

  const AutoConnectPolesCommand({required this.newEdges});

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    for (final edge in newEdges) {
      updatedEdges[edge.id] = edge;
    }
    return MandapLayout(
      nodes: currentLayout.nodes,
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    final updatedEdges = Map<EdgeId, MandapEdge>.from(currentLayout.edges);
    for (final edge in newEdges) {
      updatedEdges.remove(edge.id);
    }
    return MandapLayout(
      nodes: currentLayout.nodes,
      edges: Map.unmodifiable(updatedEdges),
      zones: currentLayout.zones,
    );
  }

  @override
  String get description => 'Auto-connect 4 poles with trusses';

  /// Helper utility to create 4 perimeter edges given 4 pole nodes.
  static List<MandapEdge>? buildPerimeterEdges(List<MandapNode> fourPoles) {
    if (fourPoles.length != 4) return null;

    final sorted = List<MandapNode>.from(fourPoles);
    final cx = sorted.map((p) => p.x).reduce((a, b) => a + b) / 4.0;
    final cz = sorted.map((p) => p.z).reduce((a, b) => a + b) / 4.0;

    sorted.sort((a, b) {
      final angleA = math.atan2(a.z - cz, a.x - cx);
      final angleB = math.atan2(b.z - cz, b.x - cx);
      return angleA.compareTo(angleB);
    });

    final ts = DateTime.now().microsecondsSinceEpoch;
    final edges = <MandapEdge>[];

    for (var i = 0; i < 4; i++) {
      final start = sorted[i];
      final end = sorted[(i + 1) % 4];
      edges.add(
        MandapEdge(
          id: EdgeId('auto_truss_${ts}_$i'),
          startNodeId: start.id,
          endNodeId: end.id,
          role: TrussMemberRole.upper,
          profile: EdgeProfile.box,
        ),
      );
    }

    return edges;
  }
}
