import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart';

void main() {
  group('400x400 Large Structure 3D Verification', () {
    test('Mandap3DController frames 400x400 structure fully within viewport bounds', () {
      final editorController = MandapEditorController();
      final controller3D = Mandap3DController();

      // Configure a 400x400 structure with 30ft box spacing
      editorController.reconfigureTrussDimensions(
        plotLength: 400.0,
        plotWidth: 400.0,
        trussSize: 30.0,
        poleHeight: 20.0,
        includeTowers: true,
      );

      // Fit camera for mobile portrait viewport (e.g. 390x844)
      const mobileViewport = Size(390.0, 844.0);
      controller3D.fitCamera(editorController.layout, viewportSize: mobileViewport);

      // Camera center must be centered on the 400x400 plot
      expect(controller3D.cameraCenterTarget.x, closeTo(200.0, 0.5));
      expect(controller3D.cameraCenterTarget.z, closeTo(200.0, 0.5));

      // Camera distance must be large enough (> 1200 ft) to fit the whole structure without clipping
      expect(controller3D.cameraDistance, greaterThan(1200.0));

      // Zooming out must NOT be artificially capped at 300 ft
      controller3D.zoomCamera(1.5);
      expect(controller3D.cameraDistance, greaterThan(1500.0));
    });

    testWidgets('Mandap3DPainter paints 400x400 structure without crashing or overflow', (tester) async {
      final editorController = MandapEditorController();
      final controller3D = Mandap3DController();

      editorController.reconfigureTrussDimensions(
        plotLength: 400.0,
        plotWidth: 400.0,
        trussSize: 30.0,
        poleHeight: 20.0,
        includeTowers: true,
      );

      const viewport = Size(390.0, 844.0);
      controller3D.fitCamera(editorController.layout, viewportSize: viewport);
      controller3D.syncScene(editorController.layout, editorController.result);

      final painter = Mandap3DPainter(
        layout: editorController.layout,
        result: editorController.result,
        controller: controller3D,
        editorController: editorController,
        plotWidth: 400.0,
        plotDepth: 400.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, viewport);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
