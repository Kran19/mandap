import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/infrastructure/layout_serializer.dart';

void main() {
  group('LayoutSerializer Round Trip & Precision Verification', () {
    test('Mixed layout serializes and deserializes exactly', () {
      final nodes = <NodeId, MandapNode>{
        const NodeId('n1'): const MandapNode(
          id: NodeId('n1'),
          x: 0.10,
          z: 0.90,
          type: NodeType.pole,
          width: 1.0,
          depth: 1.0,
        ),
        const NodeId('n2'): const MandapNode(
          id: NodeId('n2'),
          x: 1.25,
          z: 2.75,
          type: NodeType.stage,
          width: 6.0,
          depth: 4.0,
          height: 2.5,
          rotation: 0.654,
          elevation: 0.0,
        ),
        const NodeId('n3'): const MandapNode(
          id: NodeId('n3'),
          x: 5.10,
          z: 3.20,
          type: NodeType.carpet,
          width: 8.0,
          depth: 6.0,
          height: 0.05,
          rotation: 0.213,
          elevation: 0.0,
        ),
      };

      final originalLayout = MandapLayout(nodes: nodes, edges: const {});

      final jsonMap = LayoutSerializer.toJson(originalLayout);
      final restoredLayout = LayoutSerializer.fromJson(jsonMap);

      expect(restoredLayout.nodes.length, 3);

      final restoredPole = restoredLayout.getNode(const NodeId('n1'))!;
      expect(restoredPole.type, NodeType.pole);
      expect((restoredPole.x - 0.10).abs(), lessThan(1e-9));
      expect((restoredPole.z - 0.90).abs(), lessThan(1e-9));

      final restoredStage = restoredLayout.getNode(const NodeId('n2'))!;
      expect(restoredStage.type, NodeType.stage);
      expect((restoredStage.x - 1.25).abs(), lessThan(1e-9));
      expect((restoredStage.z - 2.75).abs(), lessThan(1e-9));
      expect((restoredStage.width! - 6.0).abs(), lessThan(1e-9));
      expect((restoredStage.depth! - 4.0).abs(), lessThan(1e-9));
      expect((restoredStage.height! - 2.5).abs(), lessThan(1e-9));
      expect((restoredStage.rotation - 0.654).abs(), lessThan(1e-9));
      expect((restoredStage.elevation - 0.0).abs(), lessThan(1e-9));

      final restoredCarpet = restoredLayout.getNode(const NodeId('n3'))!;
      expect(restoredCarpet.type, NodeType.carpet);
      expect((restoredCarpet.x - 5.10).abs(), lessThan(1e-9));
      expect((restoredCarpet.z - 3.20).abs(), lessThan(1e-9));
      expect((restoredCarpet.width! - 8.0).abs(), lessThan(1e-9));
      expect((restoredCarpet.depth! - 6.0).abs(), lessThan(1e-9));
      expect((restoredCarpet.height! - 0.05).abs(), lessThan(1e-9));
    });

    test('Old schema defaults are applied correctly', () {
      final oldJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [
            {
              'id': 'n_stage',
              'x': 10.0,
              'z': 10.0,
              'type': 'stage',
              'isLocked': false
            },
            {
              'id': 'n_truss',
              'x': 5.0,
              'z': 5.0,
              'type': 'corner',
              'isLocked': false
            }
          ],
          'edges': []
        }
      };

      final restored = LayoutSerializer.fromJson(oldJson);

      final stage = restored.getNode(const NodeId('n_stage'))!;
      expect(stage.width, 10.0);
      expect(stage.depth, 10.0);
      expect(stage.height, 2.0);

      final truss = restored.getNode(const NodeId('n_truss'))!;
      expect(truss.width, isNull);
      expect(truss.depth, isNull);
      expect(truss.height, isNull);
    });
  });

  // ── MANDATORY REGRESSION TESTS: Zone → Node Migration (PHASE C-V2) ───────
  group('Legacy Zone to Node Migration', () {
    test('Legacy zones are promoted to authoritative nodes on deserialization', () {
      final legacyJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [
            {'id': 'truss_n1', 'x': 0.0, 'z': 0.0, 'type': 'corner', 'isLocked': false},
            {'id': 'pole_1', 'x': 5.0, 'z': 5.0, 'type': 'pole', 'isLocked': false, 'height': 12.0, 'width': 0.5, 'depth': 0.5},
          ],
          'edges': [],
          'zones': [
            {'id': 'zone_floor_1', 'type': 'flooring', 'x1': 0.0, 'y1': 0.0, 'x2': 40.0, 'y2': 30.0},
            {'id': 'zone_stage_1', 'type': 'stage', 'x1': 10.0, 'y1': 10.0, 'x2': 30.0, 'y2': 20.0},
          ],
        }
      };

      final layout = LayoutSerializer.fromJson(legacyJson);

      expect(layout.nodes.containsKey(const NodeId('truss_n1')), isTrue);
      expect(layout.nodes[const NodeId('truss_n1')]!.type, NodeType.corner);
      expect(layout.nodes.containsKey(const NodeId('pole_1')), isTrue);
      expect(layout.nodes[const NodeId('pole_1')]!.type, NodeType.pole);

      expect(layout.nodes.containsKey(const NodeId('zone_floor_1')), isTrue);
      expect(layout.nodes[const NodeId('zone_floor_1')]!.type, NodeType.carpet);
      expect(layout.nodes.containsKey(const NodeId('zone_stage_1')), isTrue);
      expect(layout.nodes[const NodeId('zone_stage_1')]!.type, NodeType.stage);

      // 2 original + 2 promoted from zones = 4
      expect(layout.nodes.length, 4);
      expect(layout.zones, isEmpty);
    });

    test('Zone is NOT duplicated when authoritative node with same ID exists', () {
      final mixedJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [
            {
              'id': 'zone_floor_1',
              'x': 2.0,
              'z': 3.0,
              'type': 'carpet',
              'isLocked': false,
              'width': 50.0,
              'depth': 35.0,
            },
          ],
          'edges': [],
          'zones': [
            // Same ID, different geometry — authoritative node wins
            {'id': 'zone_floor_1', 'type': 'flooring', 'x1': 0.0, 'y1': 0.0, 'x2': 40.0, 'y2': 30.0},
          ],
        }
      };

      final layout = LayoutSerializer.fromJson(mixedJson);

      expect(layout.nodes.length, 1);
      expect(layout.nodes[const NodeId('zone_floor_1')]!.type, NodeType.carpet);
      // Authoritative node dimensions win (50×35)
      expect(layout.nodes[const NodeId('zone_floor_1')]!.width, 50.0);
      expect(layout.nodes[const NodeId('zone_floor_1')]!.depth, 35.0);
    });

    test('Adding stage node does NOT remove existing truss, pole, or flooring nodes', () {
      final initial = MandapLayout(
        nodes: {
          const NodeId('truss_n1'): const MandapNode(id: NodeId('truss_n1'), x: 0, z: 0, type: NodeType.corner),
          const NodeId('pole_1'): const MandapNode(id: NodeId('pole_1'), x: 5, z: 5, type: NodeType.pole),
          const NodeId('carpet_1'): const MandapNode(id: NodeId('carpet_1'), x: 0, z: 0, type: NodeType.carpet, width: 40, depth: 30),
        },
        edges: const {},
      );

      final withStage = initial.withNode(const MandapNode(
        id: NodeId('stage_1'),
        x: 10,
        z: 10,
        type: NodeType.stage,
        width: 20,
        depth: 10,
        height: 2,
      ));

      expect(withStage.nodes.length, 4);
      expect(withStage.nodes.containsKey(const NodeId('truss_n1')), isTrue);
      expect(withStage.nodes.containsKey(const NodeId('pole_1')), isTrue);
      expect(withStage.nodes.containsKey(const NodeId('carpet_1')), isTrue);
      expect(withStage.nodes.containsKey(const NodeId('stage_1')), isTrue);
      // Flooring dimensions are preserved
      expect(withStage.nodes[const NodeId('carpet_1')]!.width, 40.0);
    });

    test('V2 serializer writes an empty zones array', () {
      final layout = MandapLayout(
        nodes: {
          const NodeId('stage_1'): const MandapNode(
            id: NodeId('stage_1'),
            x: 0,
            z: 0,
            type: NodeType.stage,
            width: 20,
            depth: 10,
            height: 2,
          ),
        },
        edges: const {},
      );

      final json = LayoutSerializer.toJson(layout);
      final zones = (json['layout'] as Map)['zones'] as List;
      expect(zones, isEmpty);
    });

    test('Historical ProjectVersion JSON is deeply immutable during deserialization', () {
      final legacyJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [
            {'id': 'truss_n1', 'x': 0.0, 'z': 0.0, 'type': 'corner', 'isLocked': false},
          ],
          'edges': [],
          'zones': [
            {'id': 'zone_stage_1', 'type': 'stage', 'x1': 10.0, 'y1': 10.0, 'x2': 30.0, 'y2': 20.0},
          ],
        }
      };

      // Create a deep copy for comparison
      final originalJsonStr = jsonEncode(legacyJson);

      final layout = LayoutSerializer.fromJson(legacyJson);

      // Verify legacy JSON object is entirely unchanged
      expect(jsonEncode(legacyJson), originalJsonStr);
      
      // Verify migration worked
      expect(layout.nodes.containsKey(const NodeId('zone_stage_1')), isTrue);
    });

    test('Malformed legacy zone throws SerializationException without partial data corruption', () {
      final malformedJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [],
          'edges': [],
          'zones': [
            // Missing 'type' and coordinates
            {'id': 'zone_broken_1'},
          ],
        }
      };

      expect(
        () => LayoutSerializer.fromJson(malformedJson),
        throwsA(isA<SerializationException>()),
      );
    });

    test('Round-trip migration serializes normalized nodes and empty zones array', () {
      final legacyJson = {
        'schemaVersion': 1,
        'layout': {
          'nodes': [],
          'edges': [],
          'zones': [
            {'id': 'zone_floor_1', 'type': 'flooring', 'x1': 0.0, 'y1': 0.0, 'x2': 40.0, 'y2': 30.0},
          ],
        }
      };

      final layout = LayoutSerializer.fromJson(legacyJson);
      
      // Re-serialize the migrated layout
      final newJson = LayoutSerializer.toJson(layout);
      
      final layoutMap = newJson['layout'] as Map<String, dynamic>;
      final nodes = layoutMap['nodes'] as List<dynamic>;
      final zones = layoutMap['zones'] as List<dynamic>;

      // Legacy zone is now a formal node
      expect(nodes.length, 1);
      expect(nodes[0]['id'], 'zone_floor_1');
      expect(nodes[0]['type'], 'carpet');
      expect(nodes[0]['width'], 40.0);
      expect(nodes[0]['depth'], 30.0);

      // Zones list is strictly empty
      expect(zones, isEmpty);
    });
  });
}
