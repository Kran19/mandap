import '../domain/entities/mandap_layout.dart';
import '../domain/entities/mandap_node.dart';
import '../domain/entities/mandap_edge.dart';
import '../domain/entities/mandap_zone.dart';
import '../domain/entities/node_id.dart';
import '../domain/entities/edge_id.dart';
import '../../../core/geometry/length.dart';
import '../../../core/errors/api_exceptions.dart';

/// Serializes/deserializes [MandapLayout] to/from a JSON map.
///
/// # Schema Version History
/// - v1: Original format with nodes, edges, zones list.
///
/// # Zone → Node Migration (V2 Compatibility Layer)
/// Legacy `zones` (ZoneType.stage / ZoneType.flooring) are transparently
/// promoted to [NodeType.stage] / [NodeType.carpet] nodes during deserialization.
///
/// **Safety Rules (Mandatory — see PHASE C-V2 audit):**
///   1. If an authoritative node with a matching zone ID already exists, the
///      zone is SKIPPED to prevent duplicates.
///   2. A legacy zone is converted to a node ONLY if no node with that ID is
///      present in the `nodes` map.
///   3. Malformed zone entries produce a [SerializationException]; they are
///      never silently swallowed.
///   4. Deserialization does NOT mutate the persisted JSON and does NOT mark
///      the resulting layout as dirty. The caller (LocalProjectStore /
///      ProjectSyncService) is responsible for dirty-state management.
///
/// New code must NEVER write new [MandapZone] objects. [MandapZone] is a
/// read-compatibility format only from V2 onwards.
class LayoutSerializer {
  static const int currentSchemaVersion = 1;

  static Map<String, dynamic> toJson(MandapLayout layout) {
    final nodesList = layout.nodes.values.map((node) {
      final json = <String, dynamic>{
        'id': node.id.value,
        'x': node.x,
        'z': node.z,
        'type': node.type.name,
        'isLocked': node.isLocked,
      };

      if (node.width != null) json['width'] = node.width;
      if (node.depth != null) json['depth'] = node.depth;
      if (node.height != null) json['height'] = node.height;
      if (node.rotation != 0.0) json['rotation'] = node.rotation;
      if (node.elevation != 0.0) json['elevation'] = node.elevation;

      return json;
    }).toList();

    final edgesList = layout.edges.values.map((edge) {
      return {
        'id': edge.id.value,
        'startNodeId': edge.startNodeId.value,
        'endNodeId': edge.endNodeId.value,
        if (edge.requestedLength != null) 'requestedLength': edge.requestedLength!.feet,
      };
    }).toList();

    // V2: No longer write zones. Emit an empty list for forward-compatibility
    // of any V1 consumers that expect the key to exist.
    return {
      'schemaVersion': currentSchemaVersion,
      'layout': {
        'nodes': nodesList,
        'edges': edgesList,
        'zones': <dynamic>[],
      }
    };
  }

  static MandapLayout fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw UnsupportedLayoutSchemaException(
          'Unsupported schema version: ${json['schemaVersion']}. Expected: $currentSchemaVersion');
    }

    final layoutData = json['layout'] as Map<String, dynamic>?;
    if (layoutData == null) {
      throw SerializationException('Missing "layout" object in envelope');
    }

    final nodesList = (layoutData['nodes'] as List<dynamic>?) ?? [];
    final edgesList = (layoutData['edges'] as List<dynamic>?) ?? [];
    final zonesList = (layoutData['zones'] as List<dynamic>?) ?? [];

    // ── 1. Parse authoritative nodes first ────────────────────────────────
    final nodes = <NodeId, MandapNode>{};
    for (var n in nodesList) {
      final id = NodeId(n['id'] as String);

      NodeType type = NodeType.corner;
      if (n['type'] != null) {
        final typeStr = n['type'] as String;
        type = NodeType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => NodeType.corner,
        );
      }

      nodes[id] = MandapNode(
        id: id,
        x: (n['x'] as num).toDouble(),
        z: (n['z'] as num).toDouble(),
        type: type,
        isLocked: (n['isLocked'] as bool?) ?? false,
        width: n['width'] != null ? (n['width'] as num).toDouble() : _defaultWidth(type),
        depth: n['depth'] != null ? (n['depth'] as num).toDouble() : _defaultDepth(type),
        height: n['height'] != null ? (n['height'] as num).toDouble() : _defaultHeight(type),
        rotation: n['rotation'] != null ? (n['rotation'] as num).toDouble() : 0.0,
        elevation: n['elevation'] != null ? (n['elevation'] as num).toDouble() : 0.0,
      );
    }

    // ── 2. Migrate legacy zones (deduplicating against existing nodes) ────
    // This loop implements the mandatory Zone → Node compatibility layer.
    // It does NOT modify the persisted JSON and does NOT mark the layout dirty.
    for (var z in zonesList) {
      late MandapZone zone;
      try {
        zone = MandapZone.fromJson(z as Map<String, dynamic>);
      } catch (e) {
        throw SerializationException(
          'Failed to parse legacy zone entry: $z. Error: $e',
        );
      }

      final nodeId = NodeId(zone.id);

      // Rule 1: If an authoritative node already exists with this ID, skip.
      // The authoritative node takes precedence — do not overwrite or duplicate.
      if (nodes.containsKey(nodeId)) {
        continue;
      }

      // Rule 2: Convert zone to authoritative node type.
      final nodeType = zone.type == ZoneType.stage ? NodeType.stage : NodeType.carpet;

      final zoneWidth = zone.width;
      final zoneDepth = zone.height; // MandapZone.height = y2-y1 = depth in feet
      // Place node at the top-left corner of the zone rect.
      final nodeX = zone.left;
      final nodeZ = zone.top;

      nodes[nodeId] = MandapNode(
        id: nodeId,
        x: nodeX,
        z: nodeZ,
        type: nodeType,
        width: zoneWidth > 0 ? zoneWidth : _defaultWidth(nodeType),
        depth: zoneDepth > 0 ? zoneDepth : _defaultDepth(nodeType),
        height: _defaultHeight(nodeType),
      );
    }

    // ── 3. Parse edges ────────────────────────────────────────────────────
    final edges = <EdgeId, MandapEdge>{};
    for (var e in edgesList) {
      final id = EdgeId(e['id'] as String);

      Length? requestedLength;
      if (e['requestedLength'] != null) {
        requestedLength = Length.fromFeet((e['requestedLength'] as num).toDouble());
      }

      edges[id] = MandapEdge(
        id: id,
        startNodeId: NodeId(e['startNodeId'] as String),
        endNodeId: NodeId(e['endNodeId'] as String),
        requestedLength: requestedLength,
      );
    }

    // zones are always empty after migration — the list is a compatibility artifact only.
    return MandapLayout(nodes: nodes, edges: edges, zones: const []);
  }

  static double? _defaultWidth(NodeType type) {
    if (type == NodeType.stage || type == NodeType.carpet) return 10.0;
    if (type == NodeType.pole) return 1.0;
    return null;
  }

  static double? _defaultDepth(NodeType type) {
    if (type == NodeType.stage || type == NodeType.carpet) return 10.0;
    if (type == NodeType.pole) return 1.0;
    return null;
  }

  static double? _defaultHeight(NodeType type) {
    if (type == NodeType.stage) return 2.0; // 2 ft platform
    if (type == NodeType.carpet) return 0.05; // ~0.6 inches
    if (type == NodeType.pole) return null; // Uses global height if null
    return null;
  }
}
