import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/pole/domain/models/pole_calculation_input.dart';
import 'package:mandap/features/pole/domain/services/pole_calculation_service.dart';

void main() {
  group('PoleCalculationService Regression Tests', () {
    final service = const PoleCalculationService();

    void verifyResult(double l, double w, int expectedVertical, int expectedHorizontal, {int? expectedCeiling}) {
      final result = service.calculate(PoleCalculationInput(plotLength: l, plotWidth: w));
      expect(result.totalVerticalPoles, expectedVertical, reason: 'Failed vertical poles for $l x $w');
      expect(result.totalHorizontalPipes, expectedHorizontal, reason: 'Failed horizontal pipes for $l x $w');
      if (expectedCeiling != null) {
        expect(result.totalCeilingSections, expectedCeiling, reason: 'Failed ceiling sections for $l x $w');
      }
    }

    test('15 x 15', () => verifyResult(15, 15, 4, 4, expectedCeiling: 1));
    test('15 x 30', () => verifyResult(15, 30, 6, 7, expectedCeiling: 2));
    test('15 x 45', () => verifyResult(15, 45, 8, 10, expectedCeiling: 3));
    test('15 x 60', () => verifyResult(15, 60, 10, 13, expectedCeiling: 4));
    test('15 x 75', () => verifyResult(15, 75, 12, 16, expectedCeiling: 5));
    test('15 x 90', () => verifyResult(15, 90, 14, 19, expectedCeiling: 6));

    test('30 x 30', () => verifyResult(30, 30, 9, 12, expectedCeiling: 4));
    test('30 x 45', () => verifyResult(30, 45, 12, 17, expectedCeiling: 6));
    test('30 x 60', () => verifyResult(30, 60, 15, 22, expectedCeiling: 8));
    test('30 x 75', () => verifyResult(30, 75, 18, 27, expectedCeiling: 10));
    test('30 x 90', () => verifyResult(30, 90, 21, 32, expectedCeiling: 12));

    test('45 x 45', () => verifyResult(45, 45, 16, 24, expectedCeiling: 9));
    test('45 x 60', () => verifyResult(45, 60, 20, 31, expectedCeiling: 12));
    test('45 x 75', () => verifyResult(45, 75, 24, 38, expectedCeiling: 15));
    test('45 x 90', () => verifyResult(45, 90, 28, 45, expectedCeiling: 18));

    test('60 x 60', () => verifyResult(60, 60, 25, 40, expectedCeiling: 16));
    test('60 x 75', () => verifyResult(60, 75, 30, 49, expectedCeiling: 20));
    test('60 x 90', () => verifyResult(60, 90, 35, 58, expectedCeiling: 24));
    
    test('75 x 75', () => verifyResult(75, 75, 36, 60, expectedCeiling: 25));
    test('75 x 90', () => verifyResult(75, 90, 42, 71, expectedCeiling: 30));
    
    test('90 x 90', () => verifyResult(90, 90, 49, 84, expectedCeiling: 36));
    test('90 x 105', () => verifyResult(90, 105, 56, 97, expectedCeiling: 42));
    test('90 x 120', () => verifyResult(90, 120, 63, 110, expectedCeiling: 48));
    test('90 x 135', () => verifyResult(90, 135, 70, 123, expectedCeiling: 54));
    test('90 x 150', () => verifyResult(90, 150, 77, 136, expectedCeiling: 60));
    test('90 x 165', () => verifyResult(90, 165, 84, 149, expectedCeiling: 66));
    test('90 x 180', () => verifyResult(90, 180, 91, 162, expectedCeiling: 72));
    test('90 x 195', () => verifyResult(90, 195, 98, 175, expectedCeiling: 78));
    test('90 x 210', () => verifyResult(90, 210, 105, 188, expectedCeiling: 84));
    test('90 x 225', () => verifyResult(90, 225, 112, 201, expectedCeiling: 90));

    test('100 x 100', () {
      final result = service.calculate(const PoleCalculationInput(plotLength: 100, plotWidth: 100));
      expect(result.grid.lengthBays, 7);
      expect(result.grid.widthBays, 7);
      expect(result.totalVerticalPoles, 64);
      expect(result.totalHorizontalPipes, 112);
      expect(result.totalCeilingSections, 49);
      expect(result.poleLayoutPoints.length, 64);
      
      // Verify clamp on layout points
      final maxX = result.poleLayoutPoints.map((p) => p.x).reduce(max);
      final maxZ = result.poleLayoutPoints.map((p) => p.z).reduce(max);
      expect(maxX, 100);
      expect(maxZ, 100);
    });

    test('arbitrary dimensions', () {
       verifyResult(10, 10, 4, 4);
       verifyResult(20, 15, 6, 7);
       verifyResult(20, 20, 9, 12);
       
       final res50x20 = service.calculate(const PoleCalculationInput(plotLength: 50, plotWidth: 20));
       expect(res50x20.totalVerticalPoles, 15);
       expect(res50x20.totalHorizontalPipes, 22);

       final res100x50 = service.calculate(const PoleCalculationInput(plotLength: 100, plotWidth: 50));
       expect(res100x50.totalVerticalPoles, 40);
       expect(res100x50.totalHorizontalPipes, 67);

       final res150x100 = service.calculate(const PoleCalculationInput(plotLength: 150, plotWidth: 100));
       expect(res150x100.totalVerticalPoles, 88); 
       expect(res150x100.totalHorizontalPipes, 157); 
    });

    test('Validation Tests', () {
      expect(() => service.calculate(const PoleCalculationInput(plotLength: 0, plotWidth: 10)), throwsArgumentError);
      expect(() => service.calculate(const PoleCalculationInput(plotLength: 10, plotWidth: -5)), throwsArgumentError);
      expect(() => service.calculate(const PoleCalculationInput(plotLength: double.nan, plotWidth: 10)), throwsArgumentError);
      expect(() => service.calculate(const PoleCalculationInput(plotLength: 10, plotWidth: double.infinity)), throwsArgumentError);
    });
  });
}
