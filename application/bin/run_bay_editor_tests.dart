import 'dart:io';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/services/truss_bay_detector.dart';
import 'package:mandap/features/mandap/domain/services/truss_support_spacing_calculator.dart';
import 'package:mandap/features/mandap/application/commands/resize_truss_bay_command.dart';

void main() {
  print('========================================================');
  print('MANDAP BUILDER TRUSS BAY EDITOR: 10 LOCKED TESTS SUITE');
  print('========================================================');

  int passed = 0;
  int failed = 0;

  void test(String name, void Function() fn) {
    try {
      fn();
      print('  [PASS] $name');
      passed++;
    } catch (e, st) {
      print('  [FAIL] $name');
      print('         Error: $e');
      print('         $st');
      failed++;
    }
  }

  void expect(dynamic actual, dynamic matcher, [String? reason]) {
    if (matcher is Function) {
      final res = matcher(actual);
      if (!res) throw Exception(reason ?? 'Expected match function to return true, got $actual');
    } else if (actual != matcher) {
      throw Exception(reason ?? 'Expected: $matcher, but got: $actual');
    }
  }

  const detector = TrussBayDetector();

  // 1. Partition integrity: 100x100 with 30ft generates [0,30,60,90,100] and 16 empty bays
  test('1. Partition integrity: 100x100 with 30ft generates [0,30,60,90,100] and 16 empty bays', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
      includeTowerEdges: true,
    );
    final layout = BaseTrussArchitectureGenerator.generate(params);
    final bays = detector.detectBays(layout);

    expect(bays.length, 16, 'Expected 16 bays');

    final b0 = bays.firstWhere((b) => b.id == 'bay_c0_r0');
    expect(b0.widthFt, 30.0, 'Bay 0_0 width should be 30');
    expect(b0.lengthFt, 30.0, 'Bay 0_0 length should be 30');

    final bRemainder = bays.firstWhere((b) => b.id == 'bay_c3_r3');
    expect(bRemainder.widthFt, 10.0, 'Bay 3_3 remainder width should be 10');
    expect(bRemainder.lengthFt, 10.0, 'Bay 3_3 remainder length should be 10');

    for (final bay in bays) {
      expect(bay.hasInternalMembers, false, 'Interior must be empty');
    }
  });

  // 2. Shared boundary resize: Bay 1 (30 -> 40 ft) shifts right boundary [0,30,60,90,100] -> [0,30,70,90,100]
  test('2. Shared boundary resize: Bay 1 (30 -> 40 ft) shifts right boundary [0,30,60,90,100] -> [0,30,70,90,100]', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
      includeTowerEdges: true,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);
    final initialBays = detector.detectBays(layout);
    final targetBay = initialBays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);
    expect(targetBay.widthFt, 30.0);

    final cmd = ResizeTrussBayCommand(
      bayId: targetBay.id,
      targetWidthFt: 40.0,
    );
    layout = cmd.execute(layout);

    final updatedBays = detector.detectBays(layout);
    final leftNeighbor = updatedBays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    final resizedBay = updatedBays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);
    final rightNeighbor = updatedBays.firstWhere((b) => b.columnIndex == 2 && b.rowIndex == 0);
    final lastBay = updatedBays.firstWhere((b) => b.columnIndex == 3 && b.rowIndex == 0);

    // Left neighbor untouched: 0..30
    expect(leftNeighbor.widthFt, 30.0);
    expect(leftNeighbor.minX, 0.0);
    expect(leftNeighbor.maxX, 30.0);

    // Resized bay is 40 ft: 30..70
    expect(resizedBay.minX, 30.0);
    expect(resizedBay.maxX, 70.0);
    expect(resizedBay.widthFt, 40.0);

    // Right neighbor absorbed the 10 ft: 70..90 (width 20 ft)
    expect(rightNeighbor.minX, 70.0);
    expect(rightNeighbor.maxX, 90.0);
    expect(rightNeighbor.widthFt, 20.0);

    // Last bay untouched: 90..100 (width 10 ft)
    expect(lastBay.minX, 90.0);
    expect(lastBay.maxX, 100.0);
    expect(lastBay.widthFt, 10.0);
  });

  // 3. Shared boundary node identity
  test('3. Shared boundary node identity: adjacent bays share authoritative boundary nodes and edges', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
      includeTowerEdges: true,
    );
    final layout = BaseTrussArchitectureGenerator.generate(params);
    final bays = detector.detectBays(layout);

    final bay0 = bays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    final bay1 = bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);

    expect(bay0.cornerNodeIds[1], bay1.cornerNodeIds[0]);
    expect(bay0.cornerNodeIds[2], bay1.cornerNodeIds[3]);
    expect(bay0.boundaryEdgeIds[1], bay1.boundaryEdgeIds[3]);
  });

  // 4. Ground/Upper synchronization
  test('4. Ground/Upper synchronization: Upper X/Z matches Ground X/Z after resize', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
      includeTowerEdges: true,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);
    final bays = detector.detectBays(layout);
    final targetBay = bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);

    final cmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: 40.0);
    layout = cmd.execute(layout);

    for (final groundNode in layout.nodes.values.where((n) => n.elevation < 0.1)) {
      final matchingElevated = layout.nodes.values.firstWhere(
        (n) => n.elevation > 0.1 && (n.x - groundNode.x).abs() < 0.001 && (n.z - groundNode.z).abs() < 0.001,
      );
      expect(matchingElevated.x, groundNode.x);
      expect(matchingElevated.z, groundNode.z);
    }
  });

  // 5. Y elevation preservation
  test('5. Y elevation preservation: Ground Y=0 and Upper Y=20 are strictly preserved', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
      includeTowerEdges: true,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);
    final bays = detector.detectBays(layout);
    final targetBay = bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 1);

    final cmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: 45.0, targetLengthFt: 35.0);
    layout = cmd.execute(layout);

    for (final node in layout.nodes.values) {
      if (node.id.value.contains('ground')) {
        expect(node.elevation, 0.0);
      } else {
        expect(node.elevation, 20.0);
      }
    }
  });

  // 6. Dynamic maximum validation
  test('6. Dynamic maximum validation: calculated dynamically across different configurations', () {
    // Config A: 100 ft with 4 partitions (minimum 1 ft each) -> max is 100 - (3 * 1) = 97 ft
    final paramsA = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    var layoutA = BaseTrussArchitectureGenerator.generate(paramsA);
    final baysA = detector.detectBays(layoutA);
    final bayA = baysA.first;

    final cmdAValid = ResizeTrussBayCommand(bayId: bayA.id, targetWidthFt: 97.0);
    layoutA = cmdAValid.execute(layoutA);
    final updatedA = detector.detectBays(layoutA).firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    expect(updatedA.widthFt, 97.0);

    bool threwA = false;
    try {
      final cmdAInvalid = ResizeTrussBayCommand(bayId: bayA.id, targetWidthFt: 97.1);
      cmdAInvalid.execute(BaseTrussArchitectureGenerator.generate(paramsA));
    } catch (_) {
      threwA = true;
    }
    expect(threwA, true, 'Target 97.1 ft must be rejected');

    // Config B: 60 ft with 2 partitions of 30 ft -> max is 60 - (1 * 1) = 59 ft
    final paramsB = const BaseTrussGenerationParams(
      plotWidth: 60.0,
      plotDepth: 60.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    var layoutB = BaseTrussArchitectureGenerator.generate(paramsB);
    final baysB = detector.detectBays(layoutB);
    final bayB = baysB.first;

    final cmdBValid = ResizeTrussBayCommand(bayId: bayB.id, targetWidthFt: 59.0);
    layoutB = cmdBValid.execute(layoutB);
    final updatedB = detector.detectBays(layoutB).firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    expect(updatedB.widthFt, 59.0);

    bool threwB = false;
    try {
      final cmdBInvalid = ResizeTrussBayCommand(bayId: bayB.id, targetWidthFt: 59.5);
      cmdBInvalid.execute(BaseTrussArchitectureGenerator.generate(paramsB));
    } catch (_) {
      threwB = true;
    }
    expect(threwB, true, 'Target 59.5 ft must be rejected');
  });

  // 7. Reset to default
  test('7. Reset to default restores original generated partition configuration', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);

    // Original: 30 | 30 | 30 | 10
    final bays = detector.detectBays(layout);
    final targetBay = bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);
    expect(targetBay.widthFt, 30.0);

    // Resize: 30 -> 40 ft (giving 30 | 40 | 20 | 10)
    final resizeCmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: 40.0);
    layout = resizeCmd.execute(layout);
    final resizedBays = detector.detectBays(layout);
    expect(resizedBays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0).widthFt, 40.0);

    // Reset logic: compute original partition size
    const spacingCalc = TrussSupportSpacingCalculator();
    final xPositions = spacingCalc.calculateSupportPositions(100.0, interval: 30.0);
    final originalWidth = xPositions[targetBay.columnIndex + 1] - xPositions[targetBay.columnIndex];
    expect(originalWidth, 30.0);

    final resetCmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: originalWidth);
    layout = resetCmd.execute(layout);

    // Restored: 30 | 30 | 30 | 10
    final restoredBays = detector.detectBays(layout);
    final restoredBay = restoredBays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 0);
    expect(restoredBay.widthFt, 30.0);

    final lastBay = restoredBays.firstWhere((b) => b.columnIndex == 3 && b.rowIndex == 0);
    expect(lastBay.widthFt, 10.0); // Exact remainder preserved!
  });

  // 8. Both axes resize simultaneously
  test('8. Both axes resize simultaneously in a single command', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);
    final bays = detector.detectBays(layout);
    final targetBay = bays.firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 1);
    expect(targetBay.widthFt, 30.0);
    expect(targetBay.lengthFt, 30.0);

    final cmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: 40.0, targetLengthFt: 20.0);
    layout = cmd.execute(layout);

    final updated = detector.detectBays(layout).firstWhere((b) => b.columnIndex == 1 && b.rowIndex == 1);
    expect(updated.widthFt, 40.0);
    expect(updated.lengthFt, 20.0);
  });

  // 9. Irregular structure protection
  test('9. Irregular structure: internal member presence protects bay from resize without deleting member', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    var layout = BaseTrussArchitectureGenerator.generate(params);

    final n1 = const NodeId('pen_1');
    final n2 = const NodeId('pen_2');
    final e1 = const EdgeId('pen_e1');

    layout = MandapLayout(
      nodes: {
        ...layout.nodes,
        n1: MandapNode(id: n1, x: 10.0, z: 10.0, elevation: 20.0),
        n2: MandapNode(id: n2, x: 20.0, z: 20.0, elevation: 20.0),
      },
      edges: {
        ...layout.edges,
        e1: MandapEdge(id: e1, startNodeId: n1, endNodeId: n2),
      },
    );

    final bay = detector.detectBays(layout).firstWhere((b) => b.id == 'bay_c0_r0');
    expect(bay.hasInternalMembers, true);

    bool threw = false;
    try {
      final cmd = ResizeTrussBayCommand(bayId: bay.id, targetWidthFt: 35.0);
      layout = cmd.execute(layout);
    } catch (_) {
      threw = true;
    }
    expect(threw, true, 'Resizing bay with internal members must throw');
    expect(layout.edges.containsKey(e1), true, 'Internal member must not be deleted');
  });

  // 10. Atomic Undo & Redo
  test('10. Atomic Undo and Redo restores exact structural layout and bay dimensions', () {
    final params = const BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 30.0,
      poleHeight: 20.0,
    );
    final initialLayout = BaseTrussArchitectureGenerator.generate(params);
    final initialBays = detector.detectBays(initialLayout);
    final targetBay = initialBays.firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);

    final cmd = ResizeTrussBayCommand(bayId: targetBay.id, targetWidthFt: 45.0);
    final updatedLayout = cmd.execute(initialLayout);
    final updatedBay = detector.detectBays(updatedLayout).firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    expect(updatedBay.widthFt, 45.0);

    // Undo
    final undoneLayout = cmd.undo(updatedLayout);
    final undoneBay = detector.detectBays(undoneLayout).firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    expect(undoneBay.widthFt, 30.0);

    // Redo
    final redoneLayout = cmd.redo(undoneLayout);
    final redoneBay = detector.detectBays(redoneLayout).firstWhere((b) => b.columnIndex == 0 && b.rowIndex == 0);
    expect(redoneBay.widthFt, 45.0);
  });

  print('========================================================');
  print('RESULTS: $passed PASSED, $failed FAILED');
  print('========================================================');

  if (failed > 0) {
    exit(1);
  }
}
