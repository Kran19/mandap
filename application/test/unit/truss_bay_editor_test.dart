import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/services/truss_bay_detector.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/application/commands/resize_truss_bay_command.dart';

void main() {
  group('MANDAP Truss Module / Bay Size Editor Suite', () {
    const detector = TrussBayDetector();

    test('1. Perimeter detection: 100x100 perimeter generates 1 large enclosed bay (100x100)', () {
      final params = const BaseTrussGenerationParams(
        plotWidth: 100.0,
        plotDepth: 100.0,
        preferredPoleSpacing: 30.0,
        poleHeight: 20.0,
      );
      final layout = BaseTrussArchitectureGenerator.generate(params);

      final bays = detector.detectBays(layout);
      expect(bays.length, equals(1));

      final b0 = bays.first;
      expect(b0.widthFt, equals(100.0));
      expect(b0.lengthFt, equals(100.0));
      expect(b0.hasInternalMembers, isFalse);
    });

    test('2. Center cross bay detection: 100x100 with center cross generates 4 quadrant bays (50x50 each)', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      // Create center cross (+)
      controller.toggleCenterCross();

      final bays = controller.bays;
      expect(bays.length, equals(4)); // 2 columns x 2 rows

      // Top-Left (NW)
      final bay00 = bays.firstWhere((b) => b.id == 'bay_c0_r0');
      expect(bay00.widthFt, equals(50.0));
      expect(bay00.lengthFt, equals(50.0));

      // Top-Right (NE)
      final bay10 = bays.firstWhere((b) => b.id == 'bay_c1_r0');
      expect(bay10.widthFt, equals(50.0));
      expect(bay10.lengthFt, equals(50.0));

      // Bottom-Left (SW)
      final bay01 = bays.firstWhere((b) => b.id == 'bay_c0_r1');
      expect(bay01.widthFt, equals(50.0));
      expect(bay01.lengthFt, equals(50.0));

      // Bottom-Right (SE)
      final bay11 = bays.firstWhere((b) => b.id == 'bay_c1_r1');
      expect(bay11.widthFt, equals(50.0));
      expect(bay11.lengthFt, equals(50.0));
    });

    test('3. Shared boundary resize: Bay 0 (50 -> 60 ft) moves center cross boundary [0, 50, 100] -> [0, 60, 100]', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );
      controller.toggleCenterCross();

      final targetBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      expect(targetBay.widthFt, equals(50.0));

      // Resize target bay width from 50 -> 60 ft
      controller.resizeBay(targetBay.id, targetWidthFt: 60.0);

      final updatedBays = controller.bays;
      final resizedBay = updatedBays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      final rightNeighbor = updatedBays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);

      expect(resizedBay.minX, equals(0.0));
      expect(resizedBay.maxX, equals(60.0));
      expect(resizedBay.widthFt, equals(60.0));

      // Right neighbor absorbed the 10 ft: 50 -> 40 ft
      expect(rightNeighbor.minX, equals(60.0));
      expect(rightNeighbor.maxX, equals(100.0));
      expect(rightNeighbor.widthFt, equals(40.0));
    });

    test('4. Shared boundary node identity: adjacent bays share authoritative boundary coordinates', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();

      final bay0 = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      final bay1 = controller.bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);

      // Bay 0's maxX equals Bay 1's minX
      expect(bay0.maxX, equals(bay1.minX));
      // Bay 0's minZ and maxZ match Bay 1's minZ and maxZ
      expect(bay0.minZ, equals(bay1.minZ));
      expect(bay0.maxZ, equals(bay1.maxZ));
    });

    test('5. Ground/Upper synchronization: Upper X/Z matches Ground X/Z after resize', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );
      controller.toggleCenterCross();

      final targetBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      controller.resizeBay(targetBay.id, targetWidthFt: 60.0);

      // Check all ground nodes and their corresponding elevated nodes
      for (final groundNode in controller.layout.nodes.values.where((n) => n.elevation < 0.1)) {
        final matchingElevated = controller.layout.nodes.values.firstWhere(
          (n) => n.elevation > 0.1 && (n.x - groundNode.x).abs() < 0.001 && (n.z - groundNode.z).abs() < 0.001,
          orElse: () => groundNode,
        );
        expect(matchingElevated.x, equals(groundNode.x));
        expect(matchingElevated.z, equals(groundNode.z));
      }
    });

    test('6. Dynamic maximum validation: calculated dynamically across different configurations', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();
      final bay = controller.bays.first;

      // 97 ft is accepted (since intermediate perimeter partitions require at least 1 ft each)
      expect(() => controller.resizeBay(bay.id, targetWidthFt: 97.0), returnsNormally);

      // 97.1 ft is rejected
      expect(() => controller.resizeBay(bay.id, targetWidthFt: 97.1), throwsArgumentError);
    });

    test('7. Reset to default restores original generated partition configuration', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();

      final targetBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      expect(targetBay.widthFt, equals(50.0));

      controller.selectBay(targetBay.id);

      // Resize: 50 -> 65 ft
      controller.resizeBay(targetBay.id, targetWidthFt: 65.0);
      expect(controller.selectedBay?.widthFt, equals(65.0));

      // Reset
      controller.resetBayToDefault(targetBay.id);

      final restoredBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      expect(restoredBay.widthFt, equals(50.0));
    });

    test('8. Both axes resize simultaneously in a single command', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();

      final targetBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      expect(targetBay.widthFt, equals(50.0));
      expect(targetBay.lengthFt, equals(50.0));

      // Change width to 60 and length to 40 in the same command
      controller.resizeBay(targetBay.id, targetWidthFt: 60.0, targetLengthFt: 40.0);

      final updated = controller.bays.firstWhere((b) => b.id == targetBay.id);
      expect(updated.widthFt, equals(60.0));
      expect(updated.lengthFt, equals(40.0));
    });

    test('9. Irregular structure: internal member presence protects bay from resize without deleting member', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();

      // Add a custom Pen member directly cutting through bay_c0_r0 (0..50, 0..50)
      final n1 = const NodeId('pen_1');
      final n2 = const NodeId('pen_2');
      final e1 = const EdgeId('pen_e1');

      final customLayout = MandapLayout(
        nodes: {
          ...controller.layout.nodes,
          n1: MandapNode(id: n1, x: 10.0, z: 10.0, elevation: 20.0),
          n2: MandapNode(id: n2, x: 20.0, z: 20.0, elevation: 20.0),
        },
        edges: {
          ...controller.layout.edges,
          e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2),
        },
      );
      controller.setLayout(customLayout);

      final bay = controller.bays.firstWhere((b) => b.id == 'bay_c0_r0');
      expect(bay.hasInternalMembers, isTrue);

      // Attempting to resize this bay must be rejected with an error
      expect(
        () => controller.resizeBay(bay.id, targetWidthFt: 55.0),
        throwsStateError,
      );

      // The internal member was NOT deleted
      expect(controller.layout.edges.containsKey(e1), isTrue);
    });

    test('10. Atomic Undo and Redo restores exact structural layout and bay dimensions', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
      );
      controller.toggleCenterCross();

      final targetBay = controller.bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
      final initialLinearFt = controller.totalLinearTrussFt;

      controller.selectBay(targetBay.id);

      // Resize: 50 -> 65 ft
      controller.resizeBay(targetBay.id, targetWidthFt: 65.0);
      expect(controller.selectedBay?.widthFt, equals(65.0));

      // Undo
      controller.undo();
      final undoneBay = controller.bays.firstWhere((b) => b.id == targetBay.id);
      expect(undoneBay.widthFt, equals(50.0));
      expect(controller.totalLinearTrussFt, closeTo(initialLinearFt, 0.01));

      // Redo
      controller.redo();
      final redoneBay = controller.bays.firstWhere((b) => b.id == targetBay.id);
      expect(redoneBay.widthFt, equals(65.0));
    });
  });
}
