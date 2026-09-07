import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/truss_catalog.dart';
import 'package:mandap/features/mandap/domain/entities/truss_piece_type.dart';
import 'package:mandap/features/mandap/domain/services/truss_optimizer.dart';

void main() {
  group('TrussOptimizer Dynamic Programming Tests', () {
    final catalog = TrussCatalog.sample1To20Ft();
    const edgeId = EdgeId('test_edge');

    test('Decomposes 37 ft into 20 ft + 17 ft (2 pieces)', () {
      final sol = TrussOptimizer.solveEdge(
        edgeId: edgeId,
        targetLength: Length.fromFeet(37.0),
        catalog: catalog,
      );

      expect(sol.exactFit, isTrue);
      expect(sol.pieceCount, equals(2));
      expect(
        sol.pieces.map((p) => p.length.feet).toList(),
        equals([20.0, 17.0]),
      );
    });

    test(
      'Decomposes integer test vectors 1, 10, 20, 30, 40, 60, 70 ft correctly',
      () {
        final testLengths = [1.0, 10.0, 20.0, 30.0, 40.0, 60.0, 70.0];

        for (final feet in testLengths) {
          final len = Length.fromFeet(feet);
          final sol = TrussOptimizer.solveEdge(
            edgeId: edgeId,
            targetLength: len,
            catalog: catalog,
          );

          expect(sol.exactFit, isTrue, reason: 'Failed for length $feet ft');

          // Invariant: sum of piece lengths must equal target length
          final sumFeet = sol.pieces.fold<double>(
            0.0,
            (sum, p) => sum + p.length.feet,
          );
          expect(
            sumFeet,
            equals(feet),
            reason: 'Sum of pieces does not match target $feet ft',
          );
        }
      },
    );

    test(
      '10.5 ft on integer-only catalog correctly returns exactFit = false',
      () {
        final sol = TrussOptimizer.solveEdge(
          edgeId: edgeId,
          targetLength: Length.fromFeet(10.5),
          catalog: catalog,
        );

        expect(sol.exactFit, isFalse);
        expect(sol.nearestLower, equals(Length.fromFeet(10.0)));
        expect(sol.nearestHigher, equals(Length.fromFeet(11.0)));
      },
    );

    test(
      'Half-foot target (10.5 ft) succeeds when catalog contains half-foot pieces',
      () {
        final halfFootCatalog = TrussCatalog([
          TrussPieceType(id: '0.5ft', length: Length.fromFeet(0.5)),
          ...catalog.pieceTypes,
        ]);

        final sol = TrussOptimizer.solveEdge(
          edgeId: edgeId,
          targetLength: Length.fromFeet(10.5),
          catalog: halfFootCatalog,
        );

        expect(sol.exactFit, isTrue);
        expect(
          sol.pieces.map((p) => p.length.feet).toList(),
          equals([10.0, 0.5]),
        );
      },
    );

    test('Decomposes with custom catalog (5, 10, 20 ft)', () {
      final customCatalog = TrussCatalog([
        TrussPieceType(id: '5ft', length: Length.fromFeet(5.0)),
        TrussPieceType(id: '10ft', length: Length.fromFeet(10.0)),
        TrussPieceType(id: '20ft', length: Length.fromFeet(20.0)),
      ]);

      final sol = TrussOptimizer.solveEdge(
        edgeId: edgeId,
        targetLength: Length.fromFeet(15.0),
        catalog: customCatalog,
      );

      expect(sol.exactFit, isTrue);
      expect(sol.pieceCount, equals(2));
      expect(
        sol.pieces.map((p) => p.length.feet).toList(),
        equals([10.0, 5.0]),
      );
    });

    test(
      'Handles impossible exact fit with nearest lower and higher recommendations',
      () {
        final restrictiveCatalog = TrussCatalog([
          TrussPieceType(id: '5ft', length: Length.fromFeet(5.0)),
          TrussPieceType(id: '10ft', length: Length.fromFeet(10.0)),
          TrussPieceType(id: '20ft', length: Length.fromFeet(20.0)),
        ]);

        final sol = TrussOptimizer.solveEdge(
          edgeId: edgeId,
          targetLength: Length.fromFeet(17.0),
          catalog: restrictiveCatalog,
        );

        expect(sol.exactFit, isFalse);
        expect(sol.pieces, isEmpty);
        expect(sol.nearestLower, equals(Length.fromFeet(15.0)));
        expect(sol.nearestHigher, equals(Length.fromFeet(20.0)));
      },
    );

    test(
      'Applies deterministic tie-breaking: prefer larger piece sequences',
      () {
        final sol = TrussOptimizer.solveEdge(
          edgeId: edgeId,
          targetLength: Length.fromFeet(35.0),
          catalog: catalog,
        );

        expect(sol.exactFit, isTrue);
        expect(sol.pieceCount, equals(2));
        expect(sol.pieces[0].length.feet, equals(20.0));
        expect(sol.pieces[1].length.feet, equals(15.0));
      },
    );
  });
}
