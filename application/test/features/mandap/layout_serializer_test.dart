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
          rotation: 0.654, // ~37.5 deg in rads
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
      expect(stage.height, 2.0); // Old Stage defaults
      
      final truss = restored.getNode(const NodeId('n_truss'))!;
      expect(truss.width, isNull);
      expect(truss.depth, isNull);
      expect(truss.height, isNull);
    });
  });
}
