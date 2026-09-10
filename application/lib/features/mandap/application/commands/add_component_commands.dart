import 'package:uuid/uuid.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/node_id.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/specifications/component_specifications.dart';
import 'mandap_command.dart';

/// Generates a rectangular truss structure from a [TrussSpecification].
///
/// The truss is modelled as 4 corner nodes forming a closed perimeter loop.
/// This is fully compatible with [MandapCalculationEngine] which uses edge
/// topology (nodes + edges) to derive structural loads and BOM.
///
/// Does NOT invent structural topology. Width/depth/elevation come directly
/// from the customer's measurement input.
class AddTrussCommand implements MandapCommand {
  final TrussSpecification spec;

  // Generated node/edge IDs for undo
  final List<NodeId> _generatedNodeIds = [];
  final List<EdgeId> _generatedEdgeIds = [];

  AddTrussCommand({required this.spec});

  @override
  MandapLayout execute(MandapLayout layout) {
    final uuid = Uuid();
    final ts = DateTime.now().microsecondsSinceEpoch;

    final n1Id = NodeId('truss_n1_$ts');
    final n2Id = NodeId('truss_n2_$ts');
    final n3Id = NodeId('truss_n3_$ts');
    final n4Id = NodeId('truss_n4_$ts');

    _generatedNodeIds
      ..clear()
      ..addAll([n1Id, n2Id, n3Id, n4Id]);

    final e1Id = EdgeId('truss_e1_$ts');
    final e2Id = EdgeId('truss_e2_$ts');
    final e3Id = EdgeId('truss_e3_$ts');
    final e4Id = EdgeId('truss_e4_$ts');

    _generatedEdgeIds
      ..clear()
      ..addAll([e1Id, e2Id, e3Id, e4Id]);

    // Position origin at (0, 0) by default; user can drag in editor
    final w = spec.width;
    final d = spec.depth;
    final e = spec.roofElevation;

    MandapLayout updated = layout
        .withNode(MandapNode(id: n1Id, x: 0, z: 0, type: NodeType.corner, elevation: e))
        .withNode(MandapNode(id: n2Id, x: w, z: 0, type: NodeType.corner, elevation: e))
        .withNode(MandapNode(id: n3Id, x: w, z: d, type: NodeType.corner, elevation: e))
        .withNode(MandapNode(id: n4Id, x: 0, z: d, type: NodeType.corner, elevation: e))
        .withEdge(MandapEdge(id: e1Id, startNodeId: n1Id, endNodeId: n2Id))
        .withEdge(MandapEdge(id: e2Id, startNodeId: n2Id, endNodeId: n3Id))
        .withEdge(MandapEdge(id: e3Id, startNodeId: n3Id, endNodeId: n4Id))
        .withEdge(MandapEdge(id: e4Id, startNodeId: n4Id, endNodeId: n1Id));

    return updated;
  }

  @override
  MandapLayout undo(MandapLayout layout) {
    MandapLayout updated = layout;
    for (final eid in _generatedEdgeIds) {
      updated = updated.withoutEdge(eid);
    }
    for (final nid in _generatedNodeIds) {
      updated = updated.withoutNode(nid);
    }
    return updated;
  }

  @override
  String get description => 'Add Truss (${spec.width}×${spec.depth} ft @ ${spec.roofElevation} ft)';
}

/// Adds a single support pole from a [PoleSpecification].
class AddPoleCommand implements MandapCommand {
  final PoleSpecification spec;
  late final NodeId _nodeId;

  AddPoleCommand({required this.spec});

  @override
  MandapLayout execute(MandapLayout layout) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    _nodeId = NodeId('pole_$ts');

    return layout.withNode(MandapNode(
      id: _nodeId,
      x: spec.x,
      z: spec.z,
      type: NodeType.pole,
      height: spec.height,
      width: spec.diameter,
      depth: spec.diameter,
    ));
  }

  @override
  MandapLayout undo(MandapLayout layout) => layout.withoutNode(_nodeId);

  @override
  String get description => 'Add Pole (${spec.height} ft at ${spec.x}, ${spec.z})';
}

/// Adds a carpet/flooring area from a [FlooringSpecification].
class AddCarpetCommand implements MandapCommand {
  final FlooringSpecification spec;
  late final NodeId _nodeId;

  AddCarpetCommand({required this.spec});

  @override
  MandapLayout execute(MandapLayout layout) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    _nodeId = NodeId('carpet_$ts');

    return layout.withNode(MandapNode(
      id: _nodeId,
      x: spec.x,
      z: spec.z,
      type: NodeType.carpet,
      width: spec.width,
      depth: spec.depth,
      height: spec.thickness,
      rotation: spec.rotation,
    ));
  }

  @override
  MandapLayout undo(MandapLayout layout) => layout.withoutNode(_nodeId);

  @override
  String get description => 'Add Flooring (${spec.width}×${spec.depth} ft)';
}

/// Adds a raised stage from a [StageSpecification].
class AddStageCommand implements MandapCommand {
  final StageSpecification spec;
  late final NodeId _nodeId;

  AddStageCommand({required this.spec});

  @override
  MandapLayout execute(MandapLayout layout) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    _nodeId = NodeId('stage_$ts');

    return layout.withNode(MandapNode(
      id: _nodeId,
      x: spec.x,
      z: spec.z,
      type: NodeType.stage,
      width: spec.width,
      depth: spec.depth,
      height: spec.height,
      rotation: spec.rotation,
    ));
  }

  @override
  MandapLayout undo(MandapLayout layout) => layout.withoutNode(_nodeId);

  @override
  String get description => 'Add Stage (${spec.width}×${spec.depth} ft @ ${spec.height} ft)';
}
