import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/edge_id.dart';
import '../../../../domain/entities/mandap_edge.dart';
import '../../../../domain/entities/mandap_layout.dart';
import '../../../../domain/value_objects/mandap_calculation_result.dart';
import 'truss_box_geometry_generator.dart';
import 'truss_connector_geometry.dart';
import 'truss_member_geometry.dart';
import 'truss_tower_geometry_generator.dart';

/// Immutable structural fingerprint uniquely identifying the structural state of the layout.
///
/// Invariant:
/// Camera-only movements (orbit, pan, zoom) preserve the exact same [TrussGeometryCacheKey],
/// guaranteeing ZERO geometry recalculations during view navigation.
@immutable
class TrussGeometryCacheKey {
  final String fingerprint;

  const TrussGeometryCacheKey._(this.fingerprint);

  factory TrussGeometryCacheKey.compute({
    required MandapLayout layout,
    required MandapCalculationResult result,
    required double defaultHeight,
  }) {
    final sb = StringBuffer();
    sb.write('H:$defaultHeight|');

    // Structural nodes
    for (final node in layout.nodes.values) {
      sb.write('${node.id.value}:${node.x.toStringAsFixed(2)},${node.elevation.toStringAsFixed(2)},${node.z.toStringAsFixed(2)},${node.type.name};');
    }
    sb.write('|');

    // Structural edges
    for (final edge in layout.edges.values) {
      sb.write('${edge.id.value}:${edge.startNodeId.value}->${edge.endNodeId.value}:${edge.profile?.name}:${edge.role?.name};');
    }
    sb.write('|');

    // Poles
    for (final pole in result.poles) {
      sb.write('${pole.x.toStringAsFixed(2)},${pole.z.toStringAsFixed(2)};');
    }

    return TrussGeometryCacheKey._(sb.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrussGeometryCacheKey && runtimeType == other.runtimeType && fingerprint == other.fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;
}

/// Precomputed world-space geometry container.
class TrussCachedWorldGeometry {
  final Map<EdgeId, TrussBoxGeometry> boxBeams;
  final List<TrussTowerGeometry> towers;
  final Map<String, TrussConnectorCube> connectors;
  final List<TrussTubeSegment> singleTubes;

  const TrussCachedWorldGeometry({
    required this.boxBeams,
    required this.towers,
    required this.connectors,
    required this.singleTubes,
  });
}

/// Global/pooled cache for world-space truss geometry.
class TrussGeometryCache {
  static MandapLayout? _cachedLayout;
  static MandapCalculationResult? _cachedResult;
  static double? _cachedHeight;
  static TrussGeometryCacheKey? _cachedKey;
  static TrussCachedWorldGeometry? _cachedGeometry;

  static const _boxGenerator = TrussBoxGeometryGenerator();
  static const _towerGenerator = TrussTowerGeometryGenerator();
  static const _connectorGenerator = TrussConnectorGeometryGenerator();

  /// Retrieves cached world-space geometry or computes fresh geometry if the structural fingerprint changed.
  static TrussCachedWorldGeometry getOrCreate({
    required MandapLayout layout,
    required MandapCalculationResult result,
    required double defaultHeight,
  }) {
    // 1. Fast O(1) identity check: During camera orbit/pan/zoom, instances are identical
    if (identical(layout, _cachedLayout) &&
        identical(result, _cachedResult) &&
        defaultHeight == _cachedHeight &&
        _cachedGeometry != null) {
      return _cachedGeometry!;
    }

    final key = TrussGeometryCacheKey.compute(
      layout: layout,
      result: result,
      defaultHeight: defaultHeight,
    );

    if (_cachedKey == key && _cachedGeometry != null) {
      _cachedLayout = layout;
      _cachedResult = result;
      _cachedHeight = defaultHeight;
      return _cachedGeometry!;
    }

    // Structural mutation detected -> regenerate world-space geometry
    final boxBeams = <EdgeId, TrussBoxGeometry>{};
    final singleTubes = <TrussTubeSegment>[];

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;

      // Skip vertical tower edges - towers are generated authentically with base plates
      final isTowerEdge = edge.role == TrussMemberRole.tower ||
          (startNode.x == endNode.x && startNode.z == endNode.z);
      if (isTowerEdge) continue;

      if (edge.profile == EdgeProfile.singleTube) {
        final startElev = startNode.elevation > 0 ? startNode.elevation : defaultHeight;
        final endElev = endNode.elevation > 0 ? endNode.elevation : defaultHeight;
        singleTubes.add(TrussTubeSegment(
          start: v64.Vector3(startNode.x, startElev, startNode.z),
          end: v64.Vector3(endNode.x, endElev, endNode.z),
          edgeId: edge.id,
        ));
      } else {
        final geom = _boxGenerator.generate(
          edge: edge,
          startNode: startNode,
          endNode: endNode,
          defaultHeight: defaultHeight,
        );
        boxBeams[edge.id] = geom;
      }
    }

    final towers = <TrussTowerGeometry>[];
    for (final pole in result.poles) {
      towers.add(_towerGenerator.generate(
        pole: pole,
        layout: layout,
        defaultHeight: defaultHeight,
      ));
    }

    final connectors = _connectorGenerator.generateConnectors(
      layout: layout,
      defaultHeight: defaultHeight,
    );

    final cached = TrussCachedWorldGeometry(
      boxBeams: Map.unmodifiable(boxBeams),
      towers: List.unmodifiable(towers),
      connectors: connectors,
      singleTubes: List.unmodifiable(singleTubes),
    );

    _cachedKey = key;
    _cachedLayout = layout;
    _cachedResult = result;
    _cachedHeight = defaultHeight;
    _cachedGeometry = cached;
    return cached;
  }

  /// Explicitly clears the cache (e.g. for unit tests or project reload).
  static void clear() {
    _cachedLayout = null;
    _cachedResult = null;
    _cachedHeight = null;
    _cachedKey = null;
    _cachedGeometry = null;
  }
}
