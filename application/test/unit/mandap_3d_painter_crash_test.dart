import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/generators/base_truss_architecture_generator.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test Mandap3DPainter.paint for crashes with generated layout', () {
    final params = BaseTrussGenerationParams(
      plotWidth: 100.0,
      plotDepth: 100.0,
      preferredPoleSpacing: 10.0,
      poleHeight: 20.0,
      includeCenterControlPoint: true,
    );
    final layout = BaseTrussArchitectureGenerator.generate(params);
    final editorController = MandapEditorController(
      initialWidth: 100.0,
      initialDepth: 100.0,
      initialTrussSize: 10.0,
    );
    final controller3D = Mandap3DController();
    controller3D.fitCamera(layout);
    controller3D.syncScene(layout, editorController.result);

    for (double progress = 0.0; progress <= 1.0; progress += 0.05) {
      final painter = Mandap3DPainter(
        layout: layout,
        result: editorController.result,
        controller: controller3D,
        editorController: editorController,
        animationProgress: progress,
        plotWidth: 100.0,
        plotDepth: 100.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      try {
        painter.paint(canvas, const Size(390, 844));
      } catch (e, s) {
        fail('Crashed at progress $progress: $e\n$s');
      }
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    }
  });
}
