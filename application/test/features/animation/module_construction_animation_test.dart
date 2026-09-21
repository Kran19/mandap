import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/pole/presentation/pole_calculator_screen.dart';
import 'package:mandap/features/pole/presentation/pole_calculator_controller.dart';
import 'package:mandap/features/pole/presentation/widgets/pole_3d_painter.dart';
import 'package:mandap/features/stage/presentation/stage_calculator_screen.dart';
import 'package:mandap/features/stage/presentation/stage_calculator_controller.dart';
import 'package:mandap/features/stage/presentation/widgets/stage_3d_painter.dart';
import 'package:mandap/features/flooring/presentation/flooring_calculator_screen.dart';
import 'package:mandap/features/flooring/presentation/flooring_calculator_controller.dart';
import 'package:mandap/features/flooring/presentation/widgets/flooring_3d_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module Construction 3D Animation Tests (Poles, Stage, Flooring)', () {
    test('Pole3DPainter renders across all progressive construction stages', () {
      final controller = PoleCalculatorController(initialLength: 60, initialWidth: 40, initialPoleSize: 15);
      final result = controller.result;
      expect(result, isNotNull);

      final stages = [0.0, 0.10, 0.35, 0.75, 1.0];
      for (final progress in stages) {
        final painter = Pole3DPainter(
          result: result!,
          controller: controller,
          animationProgress: progress,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(800, 600));
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      }
    });

    test('Stage3DPainter renders across all progressive construction stages', () {
      final controller = StageCalculatorController(
        initialLength: 32,
        initialWidth: 20,
        initialTableLength: 8,
        initialTableWidth: 4,
      );
      final result = controller.result;
      expect(result, isNotNull);

      final stages = [0.0, 0.15, 0.40, 0.65, 0.85, 1.0];
      for (final progress in stages) {
        final painter = Stage3DPainter(
          result: result!,
          controller: controller,
          animationProgress: progress,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(800, 600));
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      }
    });

    test('Flooring3DPainter renders across all progressive construction stages', () {
      final controller = FlooringCalculatorController(
        initialLength: 50,
        initialWidth: 30,
        initialCarpetLength: 10,
        initialCarpetWidth: 5,
      );
      final result = controller.result;
      expect(result, isNotNull);

      final stages = [0.0, 0.10, 0.35, 0.60, 0.85, 1.0];
      for (final progress in stages) {
        final painter = Flooring3DPainter(
          result: result!,
          controller: controller,
          animationProgress: progress,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(800, 600));
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      }
    });

    testWidgets('PoleCalculatorScreen starts and executes construction animation without error', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: PoleCalculatorScreen(initialLength: 60, initialWidth: 40, initialPipeSize: 15),
        ),
      );

      // Animation start
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      // Mid-way rising
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      // Full settle
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('StageCalculatorScreen starts and executes construction animation without error', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: StageCalculatorScreen(
            initialLength: 32,
            initialWidth: 20,
            initialTableLength: 8,
            initialTableWidth: 4,
          ),
        ),
      );

      // Animation start
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      // Mid-way legs & braces rising
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      // Full settle
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('FlooringCalculatorScreen starts and executes construction animation without error', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: FlooringCalculatorScreen(
            initialLength: 50,
            initialWidth: 30,
            initialCarpetLength: 10,
            initialCarpetWidth: 5,
          ),
        ),
      );

      // Animation start
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      // Mid-way unrolling
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      // Full settle
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
