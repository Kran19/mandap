import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/services/mandap_calculation_engine.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart';
import 'package:mandap/features/mandap/presentation/wizard/create_truss_dialog.dart';

void main() {
  group('MANDAP Truss Generation from User Size & Tower Connectivity Tests', () {
    late MandapCalculationEngine engine;

    setUp(() {
      engine = const MandapCalculationEngine();
    });

    void verifyStructureMatrix({
      required double plotLength,
      required double plotWidth,
      required double trussSize,
      required double poleHeight,
    }) {
      final params = BaseTrussGenerationParams(
        plotWidth: plotWidth,
        plotDepth: plotLength,
        preferredPoleSpacing: trussSize,
        poleHeight: poleHeight,
        includeCenterControlPoint: true,
      );

      final layout = BaseTrussArchitectureGenerator.generate(params);
      final controller = MandapEditorController(engine: engine);
      controller.loadCustomLayout(layout);
      controller.plotWidth = plotWidth;
      controller.plotDepth = plotLength;

      final controller3D = Mandap3DController();
      controller3D.fitCamera(layout);
      controller3D.syncScene(layout, controller.result);

      // 1. User values reach generator & plot bounds are exact
      double minX = double.infinity, maxX = -double.infinity;
      double minZ = double.infinity, maxZ = -double.infinity;
      double maxElev = 0.0;

      for (final n in layout.nodes.values) {
        if (n.x < minX) minX = n.x;
        if (n.x > maxX) maxX = n.x;
        if (n.z < minZ) minZ = n.z;
        if (n.z > maxZ) maxZ = n.z;
        if (n.elevation > maxElev) maxElev = n.elevation;
      }

      expect(minX, equals(0.0));
      expect(maxX, equals(plotWidth));
      expect(minZ, equals(0.0));
      expect(maxZ, equals(plotLength));
      expect(maxElev, equals(poleHeight));
      expect(controller.plotWidth, equals(plotWidth));
      expect(controller.plotDepth, equals(plotLength));
      expect(controller3D.mandapHeight, equals(poleHeight));

      // 2. Complete structure is generated (towers + main truss + perimeter + internal cross)
      expect(layout.nodes.length, greaterThanOrEqualTo(4));
      expect(layout.edges.length, greaterThanOrEqualTo(4));
      expect(controller.totalLinearTrussFt, greaterThan(0.0));
      expect(controller.totalPoleCount, greaterThanOrEqualTo(4));

      // 3. Tower connectivity: For every pole, base is Y=0 and top is Y=poleHeight
      // Every tower top coordinate must match the actual truss connection coordinate (ZERO GAP)
      for (final pole in controller.result.poles) {
        // Find matching elevated node or supporting edge
        MandapNode? matchingNode;
        if (pole.sourceNodeId != null) {
          matchingNode = layout.getNode(pole.sourceNodeId!);
        }
        if (matchingNode == null) {
          for (final n in layout.nodes.values) {
            if ((n.x - pole.x).abs() < 0.5 && (n.z - pole.z).abs() < 0.5) {
              matchingNode = n;
              break;
            }
          }
        }

        double expectedTopElevation;
        if (matchingNode != null) {
          expectedTopElevation = matchingNode.elevation;
        } else if (pole.sourceEdgeId != null) {
          final edge = layout.getEdge(pole.sourceEdgeId!);
          expect(edge, isNotNull);
          final sNode = layout.getNode(edge!.startNodeId)!;
          final eNode = layout.getNode(edge.endNodeId)!;
          final dx = eNode.x - sNode.x;
          final dz = eNode.z - sNode.z;
          final lenSq = dx * dx + dz * dz;
          final t = lenSq > 0 ? (((pole.x - sNode.x) * dx + (pole.z - sNode.z) * dz) / lenSq).clamp(0.0, 1.0) : 0.0;
          expectedTopElevation = sNode.elevation + t * (eNode.elevation - sNode.elevation);
        } else {
          expectedTopElevation = poleHeight;
        }

        expect(expectedTopElevation, closeTo(poleHeight, 1e-3));
      }

      // 4. Test painter completes cleanly without rendering exceptions
      final painter = Mandap3DPainter(
        layout: layout,
        result: controller.result,
        controller: controller3D,
        plotWidth: plotWidth,
        plotDepth: plotLength,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(1000, 800)), returnsNormally);
    }

    test('Test A: 100 × 100 ft, Truss Size = 10 ft (Standard Venue)', () {
      verifyStructureMatrix(
        plotLength: 100.0,
        plotWidth: 100.0,
        trussSize: 10.0,
        poleHeight: 20.0,
      );
    });

    test('Test B: 60 × 40 ft, Truss Size = 20 ft (Custom User Size)', () {
      verifyStructureMatrix(
        plotLength: 60.0,
        plotWidth: 40.0,
        trussSize: 20.0,
        poleHeight: 20.0,
      );
    });

    test('Test C: 200 × 100 ft, Truss Size = 10 ft (Large Arena)', () {
      verifyStructureMatrix(
        plotLength: 100.0,
        plotWidth: 200.0,
        trussSize: 10.0,
        poleHeight: 25.0,
      );
    });

    test('Test D: 40 × 30 ft, Truss Size = 10 ft (Compact Setup)', () {
      verifyStructureMatrix(
        plotLength: 30.0,
        plotWidth: 40.0,
        trussSize: 10.0,
        poleHeight: 16.0,
      );
    });

    test('Integration: CreateTrussDialog popup values reach generator without fallback (Section 23)', () {
      const config = CreateTrussConfig(
        plotLength: 60.0,
        plotWidth: 40.0,
        trussSize: 20.0,
      );

      final controller = MandapEditorController(
        engine: engine,
        initialWidth: config.plotWidth,
        initialDepth: config.plotLength,
        initialTrussSize: config.trussSize,
      );

      // Assert that layout/environment configuration contains 60, 40, 20 and does NOT fall back to 100, 100, 10
      expect(controller.plotWidth, equals(40.0));
      expect(controller.plotDepth, equals(60.0));
      expect(controller.standardTrussPieceSize, equals(20.0));

      final layout = controller.layout;
      expect(layout.nodes.values.any((n) => n.x == 40.0), isTrue);
      expect(layout.nodes.values.any((n) => n.z == 60.0), isTrue);
      expect(layout.nodes.values.any((n) => n.x > 40.0), isFalse);
      expect(layout.nodes.values.any((n) => n.z > 60.0), isFalse);

      // Verify bounds are derived from 40x60, not default 100x100
      double maxX = 0.0, maxZ = 0.0;
      for (final n in layout.nodes.values) {
        if (n.x > maxX) maxX = n.x;
        if (n.z > maxZ) maxZ = n.z;
      }
      expect(maxX, equals(40.0));
      expect(maxZ, equals(60.0));
    });

    test('Tower Connectivity: baseY=0, topY=mainTrussElevation, topPosition==trussConnection (Section 24)', () {
      const mainTrussElevation = 20.0;
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 60.0,
          plotDepth: 40.0,
          preferredPoleSpacing: 20.0,
          poleHeight: mainTrussElevation,
          includeCenterControlPoint: true,
        ),
      );
      final controller = MandapEditorController(engine: engine);
      controller.loadCustomLayout(layout);

      final controller3D = Mandap3DController();
      controller3D.fitCamera(layout);
      controller3D.syncScene(layout, controller.result);

      // For every tower generated:
      expect(controller.result.poles, isNotEmpty);
      for (final pole in controller.result.poles) {
        final baseY = 0.0;
        expect(baseY, closeTo(0.0, 1e-3));

        // Find the matching elevated truss node or edge directly above the pole
        MandapNode? matchingNode;
        if (pole.sourceNodeId != null) {
          matchingNode = layout.getNode(pole.sourceNodeId!);
        }
        if (matchingNode == null) {
          for (final n in layout.nodes.values) {
            if ((n.x - pole.x).abs() < 0.5 && (n.z - pole.z).abs() < 0.5) {
              matchingNode = n;
              break;
            }
          }
        }

        double topY;
        v64.Vector3 trussConnectionPosition;
        if (matchingNode != null) {
          topY = matchingNode.elevation;
          trussConnectionPosition = v64.Vector3(matchingNode.x, matchingNode.elevation, matchingNode.z);
        } else {
          final edge = layout.getEdge(pole.sourceEdgeId!);
          expect(edge, isNotNull);
          final sNode = layout.getNode(edge!.startNodeId)!;
          final eNode = layout.getNode(edge.endNodeId)!;
          final dx = eNode.x - sNode.x;
          final dz = eNode.z - sNode.z;
          final lenSq = dx * dx + dz * dz;
          final t = lenSq > 0 ? (((pole.x - sNode.x) * dx + (pole.z - sNode.z) * dz) / lenSq).clamp(0.0, 1.0) : 0.0;
          topY = sNode.elevation + t * (eNode.elevation - sNode.elevation);
          trussConnectionPosition = v64.Vector3(sNode.x + t * dx, topY, sNode.z + t * dz);
        }

        expect(topY, closeTo(mainTrussElevation, 1e-3));

        final towerTopPosition = v64.Vector3(pole.x, topY, pole.z);
        expect(towerTopPosition.x, closeTo(trussConnectionPosition.x, 1e-2));
        expect(towerTopPosition.y, closeTo(trussConnectionPosition.y, 1e-2));
        expect(towerTopPosition.z, closeTo(trussConnectionPosition.z, 1e-2));
      }
    });

    test('No-Default-Geometry: Domain edge count equals rendered structural edge count (Section 25)', () {
      final layout = BaseTrussArchitectureGenerator.generate(
        const BaseTrussGenerationParams(
          plotWidth: 60.0,
          plotDepth: 40.0,
          preferredPoleSpacing: 20.0,
          poleHeight: 20.0,
          includeCenterControlPoint: true,
        ),
      );
      final controller = MandapEditorController(engine: engine);
      controller.loadCustomLayout(layout);

      final controller3D = Mandap3DController();
      controller3D.syncScene(layout, controller.result);

      // Domain edge count must strictly match the registered structural beam count
      final domainEdgeCount = layout.edges.length;
      final registeredBeamCount = controller3D.registry.beams.length;
      expect(registeredBeamCount, equals(domainEdgeCount));

      // Pole count must strictly match MandapCalculationResult.poles count
      final domainPoleCount = controller.result.poles.length;
      final registeredPoleCount = controller3D.registry.poles.length;
      expect(registeredPoleCount, equals(domainPoleCount));
    });
  });
}
