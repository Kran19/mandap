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
import 'package:mandap/features/mandap/presentation/widgets/3d/environment/environment_geometry_cache.dart';
import 'package:mandap/features/mandap/application/coordinate_transform.dart';

void main() {
  group('MANDAP Full 3D Scene Rotation & World Environment Tests', () {
    late MandapEditorController editorController;
    late Mandap3DController controller3D;

    setUp(() {
      editorController = MandapEditorController(engine: MandapCalculationEngine());
      controller3D = Mandap3DController(mandapHeight: 20.0);
    });

    test('1. Camera orbit, pan, and zoom NEVER mutate MandapLayout or BOM', () {
      editorController.generateBaseArchitecture(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 30.0,
          poleHeight: 20.0,
        ),
      );

      final initialNodeCount = editorController.layout.nodes.length;
      final initialEdgeCount = editorController.layout.edges.length;
      final initialLinearFt = editorController.totalLinearTrussFt;
      final initialPoleCount = editorController.totalPoleCount;

      final initialNodePositions = {
        for (final entry in editorController.layout.nodes.entries)
          entry.key: v64.Vector3(entry.value.x, entry.value.elevation, entry.value.z)
      };

      // Perform camera orbit (0 -> 90 -> 180 -> 270 -> 360 degrees)
      controller3D.orbitCamera(90.0, 10.0);
      controller3D.orbitCamera(90.0, -5.0);
      controller3D.orbitCamera(90.0, 15.0);
      controller3D.orbitCamera(90.0, -20.0);

      // Perform camera pan
      controller3D.panCamera(50.0, -30.0);
      controller3D.panCamera(-25.0, 15.0);

      // Perform camera zoom
      controller3D.zoomCamera(1.25);
      controller3D.zoomCamera(0.80);

      // Invariant: Domain layout structure must remain 100% identical
      expect(editorController.layout.nodes.length, equals(initialNodeCount));
      expect(editorController.layout.edges.length, equals(initialEdgeCount));
      expect(editorController.totalLinearTrussFt, equals(initialLinearFt));
      expect(editorController.totalPoleCount, equals(initialPoleCount));

      for (final entry in editorController.layout.nodes.entries) {
        final initialPos = initialNodePositions[entry.key]!;
        expect(entry.value.x, equals(initialPos.x));
        expect(entry.value.elevation, equals(initialPos.y));
        expect(entry.value.z, equals(initialPos.z));
      }
    });

    test('2. Two-finger Pan translates cameraCenterTarget in view plane', () {
      final initialTarget = controller3D.cameraCenterTarget.clone();

      controller3D.panCamera(100.0, 50.0);

      expect(controller3D.cameraCenterTarget.x != initialTarget.x ||
             controller3D.cameraCenterTarget.y != initialTarget.y ||
             controller3D.cameraCenterTarget.z != initialTarget.z, isTrue);

      // Panning back reverses displacement
      controller3D.panCamera(-100.0, -50.0);
      expect(controller3D.cameraCenterTarget.x, closeTo(initialTarget.x, 1e-4));
      expect(controller3D.cameraCenterTarget.y, closeTo(initialTarget.y, 1e-4));
      expect(controller3D.cameraCenterTarget.z, closeTo(initialTarget.z, 1e-4));
    });

    test('3. Unified World Projection: Scene rotates coherently from 0° to 90° and 180°', () {
      const viewportSize = Size(800.0, 600.0);
      controller3D.cameraCenterTarget = v64.Vector3(50.0, 10.0, 50.0);
      controller3D.cameraDistance = 120.0;
      controller3D.cameraElevation = 35.0 * math.pi / 180.0;

      // Key world points
      final southGate = v64.Vector3(50.0, 0.0, -14.0); // South entrance
      final northFence = v64.Vector3(50.0, 0.0, 114.0); // North fence
      final trussCenter = v64.Vector3(50.0, 20.0, 50.0); // Truss roof center
      final basePlate = v64.Vector3(0.0, 0.0, 0.0); // SW base plate

      // 0° Azimuth: Eye is looking from South toward North
      controller3D.cameraAzimuth = 0.0;
      final pSouth0 = controller3D.worldToScreen(southGate, viewportSize);
      final pNorth0 = controller3D.worldToScreen(northFence, viewportSize);
      final pTruss0 = controller3D.worldToScreen(trussCenter, viewportSize);
      final pBase0 = controller3D.worldToScreen(basePlate, viewportSize);

      expect(pSouth0, isNotNull);
      expect(pNorth0, isNotNull);
      expect(pTruss0, isNotNull);
      expect(pBase0, isNotNull);

      // At 0° (camera at North looking South), North fence is closer to eye than South gate
      expect(pNorth0!.dy > pSouth0!.dy, isTrue);

      // 180° Azimuth: Camera orbits to South (looking North)
      controller3D.cameraAzimuth = math.pi;
      final pSouth180 = controller3D.worldToScreen(southGate, viewportSize);
      final pNorth180 = controller3D.worldToScreen(northFence, viewportSize);

      expect(pSouth180, isNotNull);
      expect(pNorth180, isNotNull);

      // Now camera is at South looking North, so South gate is closer to eye than North fence!
      expect(pSouth180!.dy > pNorth180!.dy, isTrue);

      // 90° Azimuth: Camera views from East toward West
      controller3D.cameraAzimuth = math.pi / 2.0;
      final pSouth90 = controller3D.worldToScreen(southGate, viewportSize);
      final pNorth90 = controller3D.worldToScreen(northFence, viewportSize);

      expect(pSouth90, isNotNull);
      expect(pNorth90, isNotNull);
      // North and South now separate horizontally along X axis
      expect((pSouth90!.dx - pNorth90!.dx).abs() > 50.0, isTrue);
    });

    test('4. Dynamic Plot Bounds adapts environment from authoritative dimensions', () {
      editorController.generateBaseArchitecture(
        const BaseTrussGenerationParams(
          plotWidth: 200.0,
          plotDepth: 100.0,
          preferredPoleSpacing: 30.0,
        ),
      );

      expect(editorController.plotWidth, equals(200.0));
      expect(editorController.plotDepth, equals(100.0));

      controller3D.fitCamera(editorController.layout);

      // Camera center target should center on the 200x100 plot
      expect(controller3D.cameraCenterTarget.x, closeTo(100.0, 1.0));
      expect(controller3D.cameraCenterTarget.z, closeTo(50.0, 1.0));
    });

    test('5. Mandap3DPainter paints world environment without errors', () {
      editorController.generateBaseArchitecture(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
        ),
      );

      final painter = Mandap3DPainter(
        layout: editorController.layout,
        result: editorController.result,
        controller: controller3D,
        plotWidth: editorController.plotWidth,
        plotDepth: editorController.plotDepth,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1024.0, 768.0);

      // Verify painting completes without throwing any exception
      expect(() => painter.paint(canvas, size), returnsNormally);

      // Verify rotation to 90°, 180°, 270° also paints cleanly
      controller3D.cameraAzimuth = math.pi / 2.0;
      expect(() => painter.paint(canvas, size), returnsNormally);

      controller3D.cameraAzimuth = math.pi;
      expect(() => painter.paint(canvas, size), returnsNormally);

      controller3D.cameraAzimuth = 3.0 * math.pi / 2.0;
      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('6. Environment rebuild count == 0 during camera-only movement', () {
      editorController.generateBaseArchitecture(
        const BaseTrussGenerationParams(
          plotWidth: 100.0,
          plotDepth: 100.0,
        ),
      );

      final painter = Mandap3DPainter(
        layout: editorController.layout,
        result: editorController.result,
        controller: controller3D,
        plotWidth: editorController.plotWidth,
        plotDepth: editorController.plotDepth,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1024.0, 768.0);

      // Initial paint primes the cache
      painter.paint(canvas, size);
      final initialRebuildCount = EnvironmentGeometryCache.rebuildCount;

      // Simulate 50 continuous camera orbit, pan, and zoom operations
      for (int i = 0; i < 50; i++) {
        controller3D.orbitCamera(5.0, 2.0);
        controller3D.panCamera(2.0, -1.0);
        controller3D.zoomCamera(1.01);
        painter.paint(canvas, size);
      }

      // Invariant: Environment geometry rebuild count MUST NOT increase during camera movement
      expect(EnvironmentGeometryCache.rebuildCount, equals(initialRebuildCount));
      expect(editorController.history.canUndo, isFalse);
    });
  });
}
