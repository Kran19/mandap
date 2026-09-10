import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/pole/presentation/pole_calculator_controller.dart';

void main() {
  group('PoleCalculatorController Tests', () {
    test('initializes with default values and calculates', () {
      final controller = PoleCalculatorController();
      expect(controller.length, 100.0);
      expect(controller.width, 100.0);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.result!.totalVerticalPoles, 64);
      expect(controller.result!.totalHorizontalPipes, 112);
      expect(controller.result!.totalCeilingSections, 49);
    });

    test('updates dimensions and recalculates', () {
      final controller = PoleCalculatorController();
      
      controller.updateDimensions(90.0, 225.0, 15.0);
      controller.calculate();

      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.result!.totalVerticalPoles, 112);
      expect(controller.result!.totalHorizontalPipes, 201);
      expect(controller.result!.totalCeilingSections, 90);
    });

    test('handles invalid dimensions', () {
      final controller = PoleCalculatorController();
      
      controller.updateDimensions(0, 50, 15.0);
      controller.calculate();

      expect(controller.error, 'Please enter valid positive dimensions.');
      expect(controller.result, isNull);
    });

    test('toggles view mode', () {
      final controller = PoleCalculatorController();
      expect(controller.viewMode, PoleViewMode.mode3D);
      
      controller.setViewMode(PoleViewMode.mode2D);
      expect(controller.viewMode, PoleViewMode.mode2D);
    });
  });
}
