import '../../../../core/geometry/length.dart';
import 'edge_id.dart';
import 'mandap_edge.dart';
import 'mandap_layout.dart';
import 'mandap_node.dart';
import 'node_id.dart';

enum PresetType { rectangle, lShape, uShape, openRun }

/// Factory and descriptor for standard Mandap layout graph presets.
class MandapPreset {
  final String id;
  final String name;
  final PresetType type;
  final String description;
  final MandapLayout Function() builder;

  MandapPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.builder,
  });

  MandapLayout createLayout() => builder();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MandapPreset && other.id == id);

  @override
  int get hashCode => id.hashCode;

  /// Preset 1: Standard 40 ft x 30 ft Rectangle
  factory MandapPreset.rectangle40x30() {
    return MandapPreset(
      id: 'rect_40x30',
      name: '40 × 30 ft Rectangle',
      type: PresetType.rectangle,
      description:
          'Standard 4-corner rectangular Mandap (40ft width, 30ft depth)',
      builder: () => MandapLayout.rectangle(
        width: Length.fromFeet(40.0),
        length: Length.fromFeet(30.0),
      ),
    );
  }

  /// Preset 2: Standard 30 ft x 20 ft Rectangle
  factory MandapPreset.rectangle30x20() {
    return MandapPreset(
      id: 'rect_30x20',
      name: '30 × 20 ft Rectangle',
      type: PresetType.rectangle,
      description:
          'Compact 4-corner rectangular Mandap (30ft width, 20ft depth)',
      builder: () => MandapLayout.rectangle(
        width: Length.fromFeet(30.0),
        length: Length.fromFeet(20.0),
      ),
    );
  }

  /// Preset 3: 40 ft x 40 ft L-Shape (6 Nodes, 6 Edges)
  factory MandapPreset.lShape40x40() {
    return MandapPreset(
      id: 'l_shape_40x40',
      name: '40 × 40 ft L-Shape',
      type: PresetType.lShape,
      description: '6-corner L-shaped Mandap structure with 20ft cutout',
      builder: () {
        final n1 = const NodeId('n1');
        final n2 = const NodeId('n2');
        final n3 = const NodeId('n3');
        final n4 = const NodeId('n4');
        final n5 = const NodeId('n5');
        final n6 = const NodeId('n6');

        final nodes = <NodeId, MandapNode>{
          n1: MandapNode(id: n1, x: 0.0, z: 0.0, type: NodeType.corner),
          n2: MandapNode(id: n2, x: 40.0, z: 0.0, type: NodeType.corner),
          n3: MandapNode(id: n3, x: 40.0, z: 20.0, type: NodeType.corner),
          n4: MandapNode(id: n4, x: 20.0, z: 20.0, type: NodeType.corner),
          n5: MandapNode(id: n5, x: 20.0, z: 40.0, type: NodeType.corner),
          n6: MandapNode(id: n6, x: 0.0, z: 40.0, type: NodeType.corner),
        };

        final e1 = const EdgeId('e1');
        final e2 = const EdgeId('e2');
        final e3 = const EdgeId('e3');
        final e4 = const EdgeId('e4');
        final e5 = const EdgeId('e5');
        final e6 = const EdgeId('e6');

        final edges = <EdgeId, MandapEdge>{
          e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2),
          e2: MandapEdge(id: e2, startNodeId: n2, endNodeId: n3),
          e3: MandapEdge(id: e3, startNodeId: n3, endNodeId: n4),
          e4: MandapEdge(id: e4, startNodeId: n4, endNodeId: n5),
          e5: MandapEdge(id: e5, startNodeId: n5, endNodeId: n6),
          e6: MandapEdge(id: e6, startNodeId: n6, endNodeId: n1),
        };

        return MandapLayout(nodes: nodes, edges: edges);
      },
    );
  }

  /// Preset 4: 40 ft x 40 ft U-Shape Courtyard (8 Nodes, 7 Edges)
  factory MandapPreset.uShape40x40() {
    return MandapPreset(
      id: 'u_shape_40x40',
      name: '40 × 40 ft U-Shape',
      type: PresetType.uShape,
      description: 'U-shaped Mandap structure with open central courtyard',
      builder: () {
        final n1 = const NodeId('n1');
        final n2 = const NodeId('n2');
        final n3 = const NodeId('n3');
        final n4 = const NodeId('n4');
        final n5 = const NodeId('n5');
        final n6 = const NodeId('n6');
        final n7 = const NodeId('n7');
        final n8 = const NodeId('n8');

        final nodes = <NodeId, MandapNode>{
          n1: MandapNode(id: n1, x: 0.0, z: 0.0, type: NodeType.corner),
          n2: MandapNode(id: n2, x: 40.0, z: 0.0, type: NodeType.corner),
          n3: MandapNode(id: n3, x: 40.0, z: 40.0, type: NodeType.openEnd),
          n4: MandapNode(id: n4, x: 30.0, z: 40.0, type: NodeType.corner),
          n5: MandapNode(id: n5, x: 30.0, z: 15.0, type: NodeType.corner),
          n6: MandapNode(id: n6, x: 10.0, z: 15.0, type: NodeType.corner),
          n7: MandapNode(id: n7, x: 10.0, z: 40.0, type: NodeType.corner),
          n8: MandapNode(id: n8, x: 0.0, z: 40.0, type: NodeType.openEnd),
        };

        final e1 = const EdgeId('e1');
        final e2 = const EdgeId('e2');
        final e3 = const EdgeId('e3');
        final e4 = const EdgeId('e4');
        final e5 = const EdgeId('e5');
        final e6 = const EdgeId('e6');
        final e7 = const EdgeId('e7');

        final edges = <EdgeId, MandapEdge>{
          e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2),
          e2: MandapEdge(id: e2, startNodeId: n2, endNodeId: n3),
          e3: MandapEdge(id: e3, startNodeId: n3, endNodeId: n4),
          e4: MandapEdge(id: e4, startNodeId: n4, endNodeId: n5),
          e5: MandapEdge(id: e5, startNodeId: n5, endNodeId: n6),
          e6: MandapEdge(id: e6, startNodeId: n6, endNodeId: n7),
          e7: MandapEdge(id: e7, startNodeId: n7, endNodeId: n8),
        };

        return MandapLayout(nodes: nodes, edges: edges);
      },
    );
  }

  /// Preset 5: 50 ft Open Linear Run
  factory MandapPreset.openRun50Ft() {
    return MandapPreset(
      id: 'open_run_50ft',
      name: '50 ft Open Linear Run',
      type: PresetType.openRun,
      description: 'Single open horizontal truss run (50ft length)',
      builder: () {
        final n1 = const NodeId('n1');
        final n2 = const NodeId('n2');
        final e1 = const EdgeId('e1');

        final nodes = <NodeId, MandapNode>{
          n1: MandapNode(id: n1, x: 0.0, z: 0.0, type: NodeType.openEnd),
          n2: MandapNode(id: n2, x: 50.0, z: 0.0, type: NodeType.openEnd),
        };

        final edges = <EdgeId, MandapEdge>{
          e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2),
        };

        return MandapLayout(nodes: nodes, edges: edges);
      },
    );
  }

  /// Returns list of all available presets.
  static List<MandapPreset> availablePresets() => [
    MandapPreset.rectangle40x30(),
    MandapPreset.rectangle30x20(),
    MandapPreset.lShape40x40(),
    MandapPreset.uShape40x40(),
    MandapPreset.openRun50Ft(),
  ];
}
