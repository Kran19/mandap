import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/domain/services/truss_support_spacing_calculator.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/services/pole_placement_engine.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';

void main() {
  group('MASTER PROMPT — Truss 30-ft Pillar Spacing & Segment Marking', () {
    const calculator = TrussSupportSpacingCalculator();

    // ── Section 29: Unit Tests for Support Spacing Calculation ───────────────

    test('Test 1: 100 ft total length -> [0, 30, 60, 90, 100], segments: [30, 30, 30, 10]', () {
      final positions = calculator.calculateSupportPositions(100.0);
      expect(positions, equals([0.0, 30.0, 60.0, 90.0, 100.0]));

      final segments = calculator.calculateSegments(100.0);
      expect(segments.length, equals(4));
      expect(segments[0], equals(const TrussSpanSegment(start: 0.0, end: 30.0, length: 30.0)));
      expect(segments[1], equals(const TrussSpanSegment(start: 30.0, end: 60.0, length: 30.0)));
      expect(segments[2], equals(const TrussSpanSegment(start: 60.0, end: 90.0, length: 30.0)));
      expect(segments[3], equals(const TrussSpanSegment(start: 90.0, end: 100.0, length: 10.0)));
    });

    test('Test 2: 90 ft total length -> [0, 30, 60, 90], segments: [30, 30, 30] (No duplicate endpoint)', () {
      final positions = calculator.calculateSupportPositions(90.0);
      expect(positions, equals([0.0, 30.0, 60.0, 90.0]));

      final segments = calculator.calculateSegments(90.0);
      expect(segments.length, equals(3));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(30.0));
      expect(segments[2].length, equals(30.0));
    });

    test('Test 3: 80 ft total length -> [0, 30, 60, 80], segments: [30, 30, 20]', () {
      final positions = calculator.calculateSupportPositions(80.0);
      expect(positions, equals([0.0, 30.0, 60.0, 80.0]));

      final segments = calculator.calculateSegments(80.0);
      expect(segments.length, equals(3));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(30.0));
      expect(segments[2].length, equals(20.0));
    });

    test('Test 4: 75 ft total length -> [0, 30, 60, 75], segments: [30, 30, 15]', () {
      final positions = calculator.calculateSupportPositions(75.0);
      expect(positions, equals([0.0, 30.0, 60.0, 75.0]));

      final segments = calculator.calculateSegments(75.0);
      expect(segments.length, equals(3));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(30.0));
      expect(segments[2].length, equals(15.0));
    });

    test('Test 5: 60 ft total length -> [0, 30, 60], segments: [30, 30]', () {
      final positions = calculator.calculateSupportPositions(60.0);
      expect(positions, equals([0.0, 30.0, 60.0]));

      final segments = calculator.calculateSegments(60.0);
      expect(segments.length, equals(2));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(30.0));
    });

    test('Test 6: 45 ft total length -> [0, 30, 45], segments: [30, 15]', () {
      final positions = calculator.calculateSupportPositions(45.0);
      expect(positions, equals([0.0, 30.0, 45.0]));

      final segments = calculator.calculateSegments(45.0);
      expect(segments.length, equals(2));
      expect(segments[0].length, equals(30.0));
      expect(segments[1].length, equals(15.0));
    });

    test('Test 7: 30 ft total length -> [0, 30], segments: [30]', () {
      final positions = calculator.calculateSupportPositions(30.0);
      expect(positions, equals([0.0, 30.0]));

      final segments = calculator.calculateSegments(30.0);
      expect(segments.length, equals(1));
      expect(segments[0].length, equals(30.0));
    });

    test('Test 8: 20 ft (< 30 ft) -> [0, 20], segments: [20] (No intermediate pillar)', () {
      final positions = calculator.calculateSupportPositions(20.0);
      expect(positions, equals([0.0, 20.0]));

      final segments = calculator.calculateSegments(20.0);
      expect(segments.length, equals(1));
      expect(segments[0].length, equals(20.0));
    });

    test('Test 9: Invalid inputs (0, -10, NaN, Infinity) are rejected with ArgumentError', () {
      expect(() => calculator.calculateSupportPositions(0.0), throwsArgumentError);
      expect(() => calculator.calculateSupportPositions(-10.0), throwsArgumentError);
      expect(() => calculator.calculateSupportPositions(double.nan), throwsArgumentError);
      expect(() => calculator.calculateSupportPositions(double.infinity), throwsArgumentError);
    });

    // ── Section 30 & 31 & 32: Two-Direction Plot & Geometry Tests ─────────────

    test('Section 30 & 31: 100 × 100 ft Base Truss Architecture Verification', () {
      const params = BaseTrussGenerationParams(
        plotWidth: 100.0,
        plotDepth: 100.0,
        preferredPoleSpacing: 30.0,
        poleHeight: 20.0,
        includeCenterControlPoint: true,
      );

      final layout = BaseTrussArchitectureGenerator.generate(params);

      // Section 32: Outermost structural boundary is exactly 100 × 100 ft
      double minX = double.infinity, maxX = -double.infinity;
      double minZ = double.infinity, maxZ = -double.infinity;
      for (final n in layout.nodes.values) {
        if (n.x < minX) minX = n.x;
        if (n.x > maxX) maxX = n.x;
        if (n.z < minZ) minZ = n.z;
        if (n.z > maxZ) maxZ = n.z;
      }
      expect(minX, equals(0.0));
      expect(maxX, equals(100.0));
      expect(minZ, equals(0.0));
      expect(maxZ, equals(100.0));

      // Perimeter nodes along South (Z = 0)
      final southNodes = layout.nodes.values
          .where((n) => n.z == 0.0 && n.support == NodeSupport.pole)
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));

      expect(southNodes.map((n) => n.x).toList(), equals([0.0, 30.0, 60.0, 90.0, 100.0]));

      // Perimeter nodes along West (X = 0)
      final westNodes = layout.nodes.values
          .where((n) => n.x == 0.0 && n.support == NodeSupport.pole)
          .toList()
        ..sort((a, b) => a.z.compareTo(b.z));

      expect(westNodes.map((n) => n.z).toList(), equals([0.0, 30.0, 60.0, 90.0, 100.0]));

      // Verify each perimeter edge segment along South has length 30, 30, 30, 10
      final southEdges = layout.edges.values.where((e) {
        final n1 = layout.getNode(e.startNodeId)!;
        final n2 = layout.getNode(e.endNodeId)!;
        return n1.z == 0.0 && n2.z == 0.0;
      }).toList();

      final southLengths = southEdges.map((e) => layout.getExactGeometricLengthFeet(e)).toList()..sort();
      expect(southLengths, equals([10.0, 30.0, 30.0, 30.0]));
    });

    test('Section 5 & 24: Pillars are generated at 0, 30, 60, 90, 100 on both axes', () {
      const params = BaseTrussGenerationParams(
        plotWidth: 100.0,
        plotDepth: 100.0,
        preferredPoleSpacing: 30.0,
        poleHeight: 20.0,
        includeCenterControlPoint: true,
      );

      final layout = BaseTrussArchitectureGenerator.generate(params);
      const engine = PolePlacementEngine();
      final poles = engine.calculatePoles(layout);

      final southPolesX = poles
          .where((p) => p.z == 0.0)
          .map((p) => p.x)
          .toList()
        ..sort();

      expect(southPolesX, equals([0.0, 30.0, 60.0, 90.0, 100.0]));

      final westPolesZ = poles
          .where((p) => p.x == 0.0)
          .map((p) => p.z)
          .toList()
        ..sort();

      expect(westPolesZ, equals([0.0, 30.0, 60.0, 90.0, 100.0]));
    });

    test('Section 17, 18, 19: No rounding up or down — 95 ft produces 30 + 30 + 30 + 5', () {
      final positions = calculator.calculateSupportPositions(95.0);
      expect(positions, equals([0.0, 30.0, 60.0, 90.0, 95.0]));

      final segments = calculator.calculateSegments(95.0);
      expect(segments.length, equals(4));
      expect(segments.map((s) => s.length).toList(), equals([30.0, 30.0, 30.0, 5.0]));
    });

    test('Section 25: Dynamic Numbering Integration — 30-ft segments and remainder receive live labels', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 30.0,
        initialPoleHeight: 20.0,
      );

      final numbering = controller.displayNumbering;
      expect(numbering.edgeNumbers.length, equals(controller.layout.edges.length));

      // Every edge has a valid 1..N presentation label
      final sortedLabels = numbering.edgeNumbers.values.toList()..sort();
      for (int i = 0; i < sortedLabels.length; i++) {
        expect(sortedLabels[i], equals(i + 1));
      }
    });
  });
}
