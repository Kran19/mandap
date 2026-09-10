import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/stage/domain/models/stage_calculation_input.dart';
import 'package:mandap/features/stage/domain/services/stage_calculation_service.dart';

void main() {
  const service = StageCalculationService();

  group('StageCalculationService', () {
    test('standard 30x20 ft stage with 4x8 ft table (Orientation A best)', () {
      const input = StageCalculationInput(
        stageLength: 30,
        stageWidth: 20,
        stageHeight: 3,
        tableLength: 4,
        tableWidth: 8,
      );

      final result = service.calculate(input);

      // Orientation A (4x8 as 4 along length, 8 along width):
      // length: ceil(30/4) = 8 tables along length
      // width:  ceil(20/8) = 3 tables along width
      // total = 24 tables

      // Orientation B (rotated: 8 along length, 4 along width):
      // length: ceil(30/8) = 4 tables along length
      // width:  ceil(20/4) = 5 tables along width
      // total = 20 tables

      // Orientation B wins! (20 < 24)
      expect(result.totalTables, equals(20));
      expect(result.tablesAlongLength, equals(4));
      expect(result.tablesAlongWidth, equals(5));
      expect(result.orientedTableLength, equals(8));
      expect(result.orientedTableWidth, equals(4));
      expect(result.coveredLength, equals(32));
      expect(result.coveredWidth, equals(20));
      expect(result.tableLayoutPoints.length, equals(20));
    });

    test('exact match 32x20 ft stage with 4x8 ft table', () {
      const input = StageCalculationInput(
        stageLength: 32,
        stageWidth: 20,
        stageHeight: 3,
        tableLength: 4,
        tableWidth: 8,
      );

      final result = service.calculate(input);

      // Orientation A: ceil(32/4)=8, ceil(20/8)=3 => 24
      // Orientation B: ceil(32/8)=4, ceil(20/4)=5 => 20
      // B wins: 20 tables
      expect(result.totalTables, equals(20));
      expect(result.coveredLength, equals(32));
      expect(result.coveredWidth, equals(20));
    });

    test('square stage and square table', () {
      const input = StageCalculationInput(
        stageLength: 10,
        stageWidth: 10,
        stageHeight: 2,
        tableLength: 5,
        tableWidth: 5,
      );

      final result = service.calculate(input);

      expect(result.totalTables, equals(4));
      expect(result.tablesAlongLength, equals(2));
      expect(result.tablesAlongWidth, equals(2));
      expect(result.coveredLength, equals(10));
      expect(result.coveredWidth, equals(10));
    });

    test('tie-breaking selects Orientation A', () {
      // 12x12 stage, 3x4 table
      // A: ceil(12/3)=4, ceil(12/4)=3 => 12
      // B: ceil(12/4)=3, ceil(12/3)=4 => 12
      // Tie -> A wins
      const input = StageCalculationInput(
        stageLength: 12,
        stageWidth: 12,
        stageHeight: 3,
        tableLength: 3,
        tableWidth: 4,
      );

      final result = service.calculate(input);

      expect(result.totalTables, equals(12));
      expect(result.orientedTableLength, equals(3));
      expect(result.orientedTableWidth, equals(4));
    });

    group('invalid inputs', () {
      test('zero stageLength throws', () {
        expect(
          () => service.calculate(const StageCalculationInput(
            stageLength: 0,
            stageWidth: 20,
            stageHeight: 3,
            tableLength: 4,
            tableWidth: 8,
          )),
          throwsArgumentError,
        );
      });

      test('negative stageWidth throws', () {
        expect(
          () => service.calculate(const StageCalculationInput(
            stageLength: 30,
            stageWidth: -5,
            stageHeight: 3,
            tableLength: 4,
            tableWidth: 8,
          )),
          throwsArgumentError,
        );
      });

      test('NaN tableLength throws', () {
        expect(
          () => service.calculate(const StageCalculationInput(
            stageLength: 30,
            stageWidth: 20,
            stageHeight: 3,
            tableLength: double.nan,
            tableWidth: 8,
          )),
          throwsArgumentError,
        );
      });

      test('Infinity stageHeight throws', () {
        expect(
          () => service.calculate(const StageCalculationInput(
            stageLength: 30,
            stageWidth: 20,
            stageHeight: double.infinity,
            tableLength: 4,
            tableWidth: 8,
          )),
          throwsArgumentError,
        );
      });

      test('zero tableWidth throws', () {
        expect(
          () => service.calculate(const StageCalculationInput(
            stageLength: 30,
            stageWidth: 20,
            stageHeight: 3,
            tableLength: 4,
            tableWidth: 0,
          )),
          throwsArgumentError,
        );
      });
    });
  });
}
