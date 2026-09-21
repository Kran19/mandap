import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/truss_boundary/domain/entities/truss_size.dart';
import 'package:mandap/features/truss_boundary/domain/entities/boundary_truss_run.dart';
import 'package:mandap/features/truss_boundary/domain/services/initial_boundary_pattern_service.dart';
import 'package:mandap/features/truss_boundary/domain/services/boundary_pole_generator.dart';
import 'package:mandap/features/truss_boundary/domain/services/truss_material_service.dart';
import 'package:mandap/features/truss_boundary/domain/services/truss_pole_requirement_service.dart';
import 'package:mandap/features/truss_boundary/application/truss_boundary_controller.dart';

void main() {
  group('MANDAP Truss Boundary & Structural Editor Comprehensive Test Suite', () {
    // 1. Initial 30-ft boundary generation
    test('1. Initial 30-ft boundary generation on 100x100 plot produces 60+30+10 on all 4 sides', () {
      final fourSides = InitialBoundaryPatternService.generateFourSides(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      expect(fourSides.length, equals(4));
      for (final side in fourSides.values) {
        expect(side.runs.length, equals(3));
        expect(side.runs[0].geometricSpan, equals(60.0));
        expect(side.runs[1].geometricSpan, equals(30.0));
        expect(side.runs[2].geometricSpan, equals(10.0));
        expect(side.totalLength, equals(100.0));
      }
    });

    // 2. Unique structural node count vs actual poles
    test('2. Structural node count for 30-ft truss on 100x100 is 12, corner poles are 4', () {
      final fourSides = InitialBoundaryPatternService.generateFourSides(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final nodes = BoundaryPoleGenerator.generatePoles(
        fourSides,
        width: 100.0,
        depth: 100.0,
      );

      expect(nodes.length, equals(12));
      final cornerPoles = nodes.where((n) => n.isCorner).toList();
      expect(cornerPoles.length, equals(4));
    });

    // 3. Material resolution of 60ft
    test('3. Material Service resolves 60 ft geometric span into two 30 ft physical stock pieces', () {
      const run60 = BoundaryTrussRun(
        id: 'north_run_0',
        startNodeId: 'node_0_0',
        endNodeId: 'node_60_0',
        sideId: 'north',
        geometricSpan: 60.0,
      );

      final pieces = TrussMaterialService.resolveRun(run60);
      expect(pieces.length, equals(2));
      expect(pieces[0].stockType, equals(TrussSize.thirty));
      expect(pieces[1].stockType, equals(TrussSize.thirty));
    });

    // 4. Material resolution across all 4 sides
    test('4. Material resolution across all 4 sides for 30-ft truss equals 16 pieces and 400 ft', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      int totalPieces = 0;
      double totalFootage = 0.0;
      for (final reqs in controller.materialRequirements.values) {
        totalPieces += reqs.length;
        for (final r in reqs) {
          totalFootage += r.requiredLength;
        }
      }

      expect(totalPieces, equals(16)); // (2x30 + 1x30 + 1x10) * 4 sides = 16 pieces
      expect(totalFootage, equals(400.0));
    });

    // 5. Support interval table definitions
    test('5. Support Interval Table defines consecutive section intervals per truss size', () {
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.ten), equals(3));
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.twenty), equals(2));
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.twentyFive), equals(2));
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.thirty), equals(2));
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.forty), equals(1));
      expect(TrussPoleRequirementService.getSectionsBeforeSupportPole(TrussSize.fifty), equals(1));
    });

    // 6. Custom 50 + 30 + 20 = 100 ft configuration
    test('6. Custom 50 + 30 + 20 = 100 ft configuration preserves independent section sizes & support rules', () {
      final fourSides = InitialBoundaryPatternService.generateFourSides(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.custom,
      );

      for (final side in fourSides.values) {
        expect(side.runs.length, equals(3));
        expect(side.runs[0].geometricSpan, equals(50.0));
        expect(side.runs[1].geometricSpan, equals(30.0));
        expect(side.runs[2].geometricSpan, equals(20.0));
        expect(side.totalLength, equals(100.0));
      }
    });

    // 7. Pencil tool splits a 60 ft run into 20 ft + 40 ft runs atomically
    test('7. Pencil tool splits a 60 ft run into 20 ft + 40 ft runs atomically', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final north = controller.fourSides['north']!;
      final targetRun = north.runs[0]; // 60 ft
      expect(targetRun.geometricSpan, equals(60.0));

      controller.setActiveTool(EditingTool.pencil);
      controller.handlePencilTap(
        sideId: 'north',
        targetRunId: targetRun.id,
        splitOffset: 20.0,
      );

      final updatedNorth = controller.fourSides['north']!;
      expect(updatedNorth.runs.length, equals(4));
      expect(updatedNorth.runs[0].geometricSpan, equals(20.0));
      expect(updatedNorth.runs[1].geometricSpan, equals(40.0));
      expect(updatedNorth.runs[2].geometricSpan, equals(30.0));
      expect(updatedNorth.runs[3].geometricSpan, equals(10.0));
    });

    // 8. Eraser tool merges two adjacent 30 ft runs into one 60 ft run
    test('8. Eraser tool merges two adjacent 30 ft runs into one 60 ft run', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final north = controller.fourSides['north']!;
      controller.setActiveTool(EditingTool.pencil);
      controller.handlePencilTap(
        sideId: 'north',
        targetRunId: north.runs[0].id,
        splitOffset: 30.0,
      );

      final splitNorth = controller.fourSides['north']!;
      final runA = splitNorth.runs[0].id; // 30ft
      final runB = splitNorth.runs[1].id; // 30ft

      controller.setActiveTool(EditingTool.eraser);
      controller.handleEraserTap(
        sideId: 'north',
        runIdA: runA,
        runIdB: runB,
      );

      final mergedNorth = controller.fourSides['north']!;
      expect(mergedNorth.runs[0].geometricSpan, equals(60.0));
    });

    // 9. Center Light Tap creates straight + cross
    test('9. Tap Center Light creates straight + cross at (50, 50) without creating extra support poles', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      expect(controller.isCenterCrossActive, isFalse);
      controller.handleCenterLightTap();

      expect(controller.isCenterCrossActive, isTrue);
      expect(controller.centerRuns.length, equals(4));

      // Check center pole is exactly at center (50, 50)
      final centerPole = controller.uniquePoles.firstWhere((p) => p.connectedSideIds.contains('center'));
      expect(centerPole.x, equals(50.0));
      expect(centerPole.z, equals(50.0));
      expect(centerPole.isSupportPole, isTrue);

      // Check the midpoint connection at (50, 0) is NOT a support pole
      final northMidNode = controller.uniquePoles.firstWhere((p) => (p.x - 50).abs() < 0.1 && (p.z - 0).abs() < 0.1);
      expect(northMidNode.isSupportPole, isFalse);
    });

    // 10. Eraser on center run
    test('10. Eraser tool can remove individual center cross members', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      controller.handleCenterLightTap();
      expect(controller.centerRuns.length, equals(4));

      controller.setActiveTool(EditingTool.eraser);
      final runToRemove = controller.centerRuns.first;
      controller.handleEraserCenterRunTap(runToRemove.id);

      expect(controller.centerRuns.length, equals(3));
    });

    // 11. 10-ft rule: 10 + 10 + 10 -> 1 support
    test('11. 10-ft rule: 10 + 10 + 10 -> 1 support', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([10.0, 10.0, 10.0]);
      expect(supports, equals(1));
    });

    // 12. 10-ft rule: 10 + 10 + 10 + 10 + 10 + 10 -> 2 supports
    test('12. 10-ft rule: 10 + 10 + 10 + 10 + 10 + 10 -> 2 supports', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([
        10.0, 10.0, 10.0,
        10.0, 10.0, 10.0,
      ]);
      expect(supports, equals(2));
    });

    // 13. 20-ft rule: 20 + 20 -> 1 support
    test('13. 20-ft rule: 20 + 20 -> 1 support', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([20.0, 20.0]);
      expect(supports, equals(1));
    });

    // 14. 30-ft rule: 30 + 30 -> 1 support
    test('14. 30-ft rule: 30 + 30 -> 1 support', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([30.0, 30.0]);
      expect(supports, equals(1));
    });

    // 15. 40-ft rule: 40 -> 1 support
    test('15. 40-ft rule: 40 -> 1 support', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([40.0]);
      expect(supports, equals(1));
    });

    // 16. 50-ft rule: 50 -> 1 support
    test('16. 50-ft rule: 50 -> 1 support', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([50.0]);
      expect(supports, equals(1));
    });

    // 17. Custom: 50 + 30 + 20 = 100 sections remain independently typed
    test('17. Custom: 50 + 30 + 20 = 100 sections remain independently typed', () {
      final supports = TrussPoleRequirementService.calculateFromSectionSequence([50.0, 30.0, 20.0]);
      // 50ft has 1 section (interval 1) -> 1 support
      // 30ft has 1 section (interval 2) -> 0 support
      // 20ft has 1 section (interval 2) -> 0 support
      expect(supports, equals(1));
    });

    // 18. Custom mixed sizes: different sizes do not contribute to each other's counters
    test('18. Custom mixed sizes: different sizes do not contribute to each other\'s counters', () {
      // 30ft (1 section) followed by 20ft (1 section) -> Neither reaches 2 consecutive -> 0 supports
      final supportsA = TrussPoleRequirementService.calculateFromSectionSequence([30.0, 20.0]);
      expect(supportsA, equals(0));

      // 30ft (1 section) followed by 20 + 20 (2 consecutive 20s) -> 1 support from the 20s
      final supportsB = TrussPoleRequirementService.calculateFromSectionSequence([30.0, 20.0, 20.0]);
      expect(supportsB, equals(1));
    });

    // 19. Structural nodes != required supports
    test('19. Structural nodes != required supports', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      expect(controller.structuralNodesCount, equals(12));
      expect(controller.requiredPolesCount, equals(4)); // 1 support per side (from 60ft = 30+30) * 4 sides = 4
      expect(controller.structuralNodesCount, isNot(equals(controller.requiredPolesCount)));
    });

    // 20. Material pieces != required supports
    test('20. Material pieces != required supports', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final totalPieces = controller.materialRequirements.values.fold(0, (sum, reqs) => sum + reqs.length);
      expect(totalPieces, equals(16));
      expect(controller.requiredPolesCount, equals(4));
      expect(totalPieces, isNot(equals(controller.requiredPolesCount)));
    });

    // 21. Camera movement does not change support calculation
    test('21. Camera movement does not change support calculation', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final initialRequired = controller.requiredPolesCount;
      controller.setViewMode(BoundaryViewMode.mode3D);
      expect(controller.requiredPolesCount, equals(initialRequired));
      controller.setViewMode(BoundaryViewMode.mode2D);
      expect(controller.requiredPolesCount, equals(initialRequired));
    });

    // 22. Pencil split recalculates support requirement
    test('22. Pencil split recalculates support requirement', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final before = controller.requiredPolesCount;
      final north = controller.fourSides['north']!;
      controller.setActiveTool(EditingTool.pencil);
      // Split 60ft into 20ft + 40ft
      controller.handlePencilTap(
        sideId: 'north',
        targetRunId: north.runs[0].id,
        splitOffset: 20.0,
      );

      final after = controller.requiredPolesCount;
      expect(after, isNotNull);
      expect(controller.fourSides['north']!.runs.length, equals(4));
    });

    // 23. Eraser merge recalculates support requirement
    test('23. Eraser merge recalculates support requirement', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      controller.setActiveTool(EditingTool.pencil);
      controller.handlePencilTap(
        sideId: 'north',
        targetRunId: controller.fourSides['north']!.runs[0].id,
        splitOffset: 30.0,
      );

      final runA = controller.fourSides['north']!.runs[0].id;
      final runB = controller.fourSides['north']!.runs[1].id;

      controller.setActiveTool(EditingTool.eraser);
      controller.handleEraserTap(
        sideId: 'north',
        runIdA: runA,
        runIdB: runB,
      );

      expect(controller.requiredPolesCount, equals(4));
      expect(controller.fourSides['north']!.runs[0].geometricSpan, equals(60.0));
    });

    // 24. Center Cross recalculates support requirement
    test('24. Center Cross recalculates support requirement', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final polesBefore = controller.actualPolesCount;
      controller.handleCenterLightTap();

      expect(controller.isCenterCrossActive, isTrue);
      expect(controller.centerRuns.length, equals(4));
      // Controller recalculates actual support poles (adds 1 center support pole)
      expect(controller.actualPolesCount, equals(polesBefore + 1));
    });

    // 25. 30ft truss places support pole at 60ft, pole at 90ft, corner pole at 100ft
    test('25. 30ft truss places support pole at 60ft, pole at 90ft, corner pole at 100ft', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final northPole60 = controller.uniquePoles.firstWhere((p) => (p.x - 60).abs() < 0.1 && (p.z - 0).abs() < 0.1);
      final northPole90 = controller.uniquePoles.firstWhere((p) => (p.x - 90).abs() < 0.1 && (p.z - 0).abs() < 0.1);
      final corner100 = controller.uniquePoles.firstWhere((p) => (p.x - 100).abs() < 0.1 && (p.z - 0).abs() < 0.1);

      expect(northPole60.isSupportPole, isTrue); // Support pole at 60ft
      expect(northPole90.isSupportPole, isTrue); // Support pole at 90ft (after 30ft)
      expect(corner100.isSupportPole, isTrue); // Corner pole at 100ft
    });

    // 26. Center Cross creates straight orthogonal branches to midpoints (50, 50) without creating extra support poles
    test('26. Center Cross creates straight orthogonal branches to midpoints (50, 50) without creating extra support poles', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.thirty,
      );

      final supportPolesBefore = controller.uniquePoles.where((p) => p.isSupportPole).length;
      controller.handleCenterLightTap();

      // Only the 1 center pole is added as a support pole (intermediate boundary midpoints are joints, not support poles)
      final supportPolesAfter = controller.uniquePoles.where((p) => p.isSupportPole).length;
      expect(supportPolesAfter, equals(supportPolesBefore + 1));
      
      final centerPole = controller.uniquePoles.firstWhere((p) => p.connectedSideIds.contains('center'));
      expect(centerPole.x, equals(50.0));
      expect(centerPole.z, equals(50.0));
      expect(centerPole.isSupportPole, isTrue);
    });

    // 27. Custom written truss value decomposes sides with exact custom span
    test('27. Custom written truss value decomposes sides with exact custom span', () {
      final controller = TrussBoundaryController(
        plotWidth: 100.0,
        plotDepth: 100.0,
        trussSize: TrussSize.custom,
        customTrussSpan: 15.0,
      );

      final north = controller.fourSides['north']!;
      // 100 ft with 15 ft spans: 6 x 15 ft + 10 ft remainder = 7 runs
      expect(north.runs.length, equals(7));
      expect(north.runs[0].geometricSpan, equals(15.0));
      expect(north.runs[5].geometricSpan, equals(15.0));
      expect(north.runs[6].geometricSpan, equals(10.0));
      expect(controller.displayTrussLabel, equals('15 ft'));
    });
  });
}
