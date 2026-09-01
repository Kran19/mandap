import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/commands/command_history.dart';
import 'package:mandap/features/mandap/application/commands/move_node_command.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_preset.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_inventory.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';

void main() {
  group('Phase 3 — Controlled Geometry & Presets Integration Tests', () {
    const engine = MandapCalculationEngine();
    final catalog = TrussCatalog.sample1To20Ft();
    final inventory = TrussInventory.sample(catalog, defaultQty: 50);

    test('L-Shape 40x40 ft preset creates valid geometry and calculates BOM', () {
      final preset = MandapPreset.lShape40x40();
      final layout = preset.createLayout();

      expect(layout.nodes.length, equals(6));
      expect(layout.edges.length, equals(6));

      final result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );

      expect(result.isValid, isTrue);
      // e1 (40ft) → 1 generated pole, e6 (40ft) → 1 generated pole, all others ≤ 30ft → 0
      expect(result.cornerPoleCount, equals(6));
      expect(result.generatedPoleCount, equals(2));
      expect(result.totalPoleCount, equals(8));
    });

    test(
      'U-Shape 40x40 ft preset creates valid geometry and calculates BOM',
      () {
        final preset = MandapPreset.uShape40x40();
        final layout = preset.createLayout();

        expect(layout.nodes.length, equals(8));
        expect(layout.edges.length, equals(7));

        final result = engine.calculate(
          layout: layout,
          catalog: catalog,
          inventory: inventory,
        );

        expect(result.isValid, isTrue);
        expect(result.cornerPoleCount, equals(8));
      },
    );

    test('Open Run 50 ft preset generates correct poles for long span', () {
      final preset = MandapPreset.openRun50Ft();
      final layout = preset.createLayout();

      final result = engine.calculate(
        layout: layout,
        catalog: catalog,
        inventory: inventory,
      );

      expect(result.isValid, isTrue);
      expect(result.cornerPoleCount, equals(2));
      expect(
        result.generatedPoleCount,
        equals(1),
      ); // 50ft span requires 1 intermediate pole at 25ft
      expect(result.totalPoleCount, equals(3));
    });

    test('CommandHistory handles multi-level execute, undo, and redo', () {
      final history = CommandHistory();
      var layout = MandapPreset.rectangle40x30().createLayout();

      final n2 = const NodeId('n2');
      expect(layout.getNode(n2)!.x, equals(40.0));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);

      // 1. Move n2 from 40 to 35
      final cmd1 = MoveNodeCommand(
        nodeId: n2,
        oldX: 40.0,
        oldZ: 0.0,
        newX: 35.0,
        newZ: 0.0,
      );
      layout = history.executeCommand(cmd1, layout);
      expect(layout.getNode(n2)!.x, equals(35.0));
      expect(history.canUndo, isTrue);
      expect(history.undoCount, equals(1));

      // 2. Move n2 from 35 to 30
      final cmd2 = MoveNodeCommand(
        nodeId: n2,
        oldX: 35.0,
        oldZ: 0.0,
        newX: 30.0,
        newZ: 0.0,
      );
      layout = history.executeCommand(cmd2, layout);
      expect(layout.getNode(n2)!.x, equals(30.0));
      expect(history.undoCount, equals(2));

      // 3. Undo cmd2 -> back to 35
      layout = history.undo(layout);
      expect(layout.getNode(n2)!.x, equals(35.0));
      expect(history.canRedo, isTrue);

      // 4. Undo cmd1 -> back to 40
      layout = history.undo(layout);
      expect(layout.getNode(n2)!.x, equals(40.0));
      expect(history.canUndo, isFalse);

      // 5. Redo cmd1 -> forward to 35
      layout = history.redo(layout);
      expect(layout.getNode(n2)!.x, equals(35.0));
      expect(history.canUndo, isTrue);
    });
  });
}
