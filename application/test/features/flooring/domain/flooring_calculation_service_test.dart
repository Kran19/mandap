import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/flooring/domain/models/flooring_calculation_input.dart';
import 'package:mandap/features/flooring/domain/services/flooring_calculation_service.dart';

void main() {
  const service = FlooringCalculationService();

  group('FlooringCalculationService', () {
    test('100x60 ft plot with 12x6 ft carpet (Orientation B selected: 85 carpets)', () {
      const input = FlooringCalculationInput(
        plotLength: 100,
        plotWidth: 60,
        carpetLength: 12,
        carpetWidth: 6,
      );

      final result = service.calculate(input);

      // Orientation A: ceil(100/12)=9, ceil(60/6)=10 => 90
      // Orientation B: ceil(100/6)=17, ceil(60/12)=5 => 85
      // Orientation B wins: 85 carpets
      expect(result.totalCarpets, equals(85));
      expect(result.carpetsAlongLength, equals(17));
      expect(result.carpetsAlongWidth, equals(5));
      expect(result.orientedCarpetLength, equals(6));
      expect(result.orientedCarpetWidth, equals(12));
      expect(result.coveredLength, equals(102));
      expect(result.coveredWidth, equals(60));
      expect(result.plotArea, equals(6000));
      expect(result.coveredArea, equals(6120));
      expect(result.extraCoverage, equals(120));
      expect(result.extraCoveragePercent, closeTo(2.0, 0.001));
      expect(result.carpetLayout.length, equals(85));
    });

    test('exact fit 60x60 ft plot with 10x10 ft carpet', () {
      const input = FlooringCalculationInput(
        plotLength: 60,
        plotWidth: 60,
        carpetLength: 10,
        carpetWidth: 10,
      );

      final result = service.calculate(input);

      expect(result.totalCarpets, equals(36));
      expect(result.carpetsAlongLength, equals(6));
      expect(result.carpetsAlongWidth, equals(6));
      expect(result.coveredLength, equals(60));
      expect(result.coveredWidth, equals(60));
      expect(result.plotArea, equals(3600));
      expect(result.coveredArea, equals(3600));
      expect(result.extraCoverage, equals(0));
      expect(result.extraCoveragePercent, equals(0));
      expect(result.carpetLayout.length, equals(36));
    });

    test('non-exact division ceiling behavior (25x25 plot, 10x10 carpet)', () {
      const input = FlooringCalculationInput(
        plotLength: 25,
        plotWidth: 25,
        carpetLength: 10,
        carpetWidth: 10,
      );

      final result = service.calculate(input);

      expect(result.totalCarpets, equals(9)); // ceil(25/10)=3 * ceil(25/10)=3
      expect(result.coveredLength, equals(30));
      expect(result.coveredWidth, equals(30));
      expect(result.extraCoverage, equals(900 - 625));
    });

    test('rotation preference when Orientation B produces fewer carpets', () {
      const input = FlooringCalculationInput(
        plotLength: 50,
        plotWidth: 20,
        carpetLength: 20,
        carpetWidth: 5,
      );

      final result = service.calculate(input);

      // Orientation A: ceil(50/20)=3, ceil(20/5)=4 => 12
      // Orientation B: ceil(50/5)=10, ceil(20/20)=1 => 10
      // B wins: 10 carpets
      expect(result.totalCarpets, equals(10));
      expect(result.orientedCarpetLength, equals(5));
      expect(result.orientedCarpetWidth, equals(20));
    });

    test('tie-breaking selects Orientation A when carpet counts are equal', () {
      const input = FlooringCalculationInput(
        plotLength: 40,
        plotWidth: 40,
        carpetLength: 10,
        carpetWidth: 20,
      );

      final result = service.calculate(input);

      // Orientation A: ceil(40/10)=4, ceil(40/20)=2 => 8
      // Orientation B: ceil(40/20)=2, ceil(40/10)=4 => 8
      // Tie -> Orientation A wins!
      expect(result.totalCarpets, equals(8));
      expect(result.orientedCarpetLength, equals(10));
      expect(result.orientedCarpetWidth, equals(20));
    });

    test('carpet larger than plot requires exactly 1 carpet', () {
      const input = FlooringCalculationInput(
        plotLength: 5,
        plotWidth: 5,
        carpetLength: 10,
        carpetWidth: 10,
      );

      final result = service.calculate(input);

      expect(result.totalCarpets, equals(1));
      expect(result.coveredLength, equals(10));
      expect(result.coveredWidth, equals(10));
    });

    test('determinism: repeated calculations produce identical results', () {
      const input = FlooringCalculationInput(
        plotLength: 100,
        plotWidth: 60,
        carpetLength: 12,
        carpetWidth: 6,
      );

      final res1 = service.calculate(input);
      final res2 = service.calculate(input);

      expect(res1.totalCarpets, equals(res2.totalCarpets));
      expect(res1.orientedCarpetLength, equals(res2.orientedCarpetLength));
      expect(res1.carpetLayout.length, equals(res2.carpetLayout.length));
      expect(res1.carpetLayout[0].x, equals(res2.carpetLayout[0].x));
      expect(res1.carpetLayout[0].z, equals(res2.carpetLayout[0].z));
    });

    group('invalid inputs throw ArgumentError', () {
      test('zero plotLength throws', () {
        expect(
          () => service.calculate(const FlooringCalculationInput(
            plotLength: 0,
            plotWidth: 60,
            carpetLength: 12,
            carpetWidth: 6,
          )),
          throwsArgumentError,
        );
      });

      test('negative plotWidth throws', () {
        expect(
          () => service.calculate(const FlooringCalculationInput(
            plotLength: 100,
            plotWidth: -10,
            carpetLength: 12,
            carpetWidth: 6,
          )),
          throwsArgumentError,
        );
      });

      test('NaN carpetLength throws', () {
        expect(
          () => service.calculate(const FlooringCalculationInput(
            plotLength: 100,
            plotWidth: 60,
            carpetLength: double.nan,
            carpetWidth: 6,
          )),
          throwsArgumentError,
        );
      });

      test('Infinity carpetWidth throws', () {
        expect(
          () => service.calculate(const FlooringCalculationInput(
            plotLength: 100,
            plotWidth: 60,
            carpetLength: 12,
            carpetWidth: double.infinity,
          )),
          throwsArgumentError,
        );
      });
    });
  });
}
