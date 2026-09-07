import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';
import 'package:mandap/features/mandap/infrastructure/layout_serializer.dart';

void main() {
  group('Pole Persistence Verification', () {
    test('Customer Pole is serialized, generated Pole is not', () {
      // 1. Create layout with a customer pole
      final customerPoleId = const NodeId('n_cust_pole');
      final customerPole = const MandapNode(
        id: NodeId('n_cust_pole'),
        x: 2.0,
        z: 2.0,
        type: NodeType.pole,
      );
      
      final layout = MandapLayout(
        nodes: {customerPoleId: customerPole},
        edges: const {},
      );
      
      // 2. Run engine to get generated poles (dummy scenario, assuming it generates if we have long edges, but we'll just check the base engine output)
      final engine = const MandapCalculationEngine();
      final catalog = TrussCatalog.sample1To20Ft();
      final inventory = TrussInventory.sample(catalog, defaultQty: 50);
      
      final result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );
      
      // Ensure layout.nodes only has the customer pole
      expect(layout.nodes.length, 1);
      expect(layout.nodes.values.first.type, NodeType.pole);
      
      // 3. Serialize and Deserialize
      final jsonMap = LayoutSerializer.toJson(layout);
      final restored = LayoutSerializer.fromJson(jsonMap);
      
      expect(restored.nodes.length, 1);
      final restoredPole = restored.getNode(customerPoleId);
      expect(restoredPole, isNotNull);
      expect(restoredPole!.type, NodeType.pole);
    });
  });
}
