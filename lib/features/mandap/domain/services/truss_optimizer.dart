import '../../../../core/geometry/length.dart';
import '../entities/edge_id.dart';
import '../entities/truss_catalog.dart';
import '../entities/truss_piece_type.dart';
import '../value_objects/edge_solution.dart';

/// State representation for Dynamic Programming optimization.
class _DPState implements Comparable<_DPState> {
  final int pieceCount;
  final List<int> pieceTicksDescending;

  const _DPState({
    required this.pieceCount,
    required this.pieceTicksDescending,
  });

  /// Compares two combinations deterministically according to business rules:
  /// 1. Minimum piece count.
  /// 2. Lexicographically larger descending sequence of piece sizes.
  @override
  int compareTo(_DPState other) {
    if (pieceCount != other.pieceCount) {
      return pieceCount.compareTo(other.pieceCount); // Lower piece count wins
    }

    // Compare lexicographically element by element
    final len = pieceCount;
    for (var i = 0; i < len; i++) {
      if (pieceTicksDescending[i] != other.pieceTicksDescending[i]) {
        // Larger piece size wins (so compare other vs this to sort larger first)
        return other.pieceTicksDescending[i].compareTo(pieceTicksDescending[i]);
      }
    }
    return 0;
  }
}

/// Dynamic Programming optimizer for deterministic truss piece decomposition.
class TrussOptimizer {
  /// Solves truss decomposition for a single edge given a [targetLength] and [catalog].
  static EdgeSolution solveEdge({
    required EdgeId edgeId,
    required Length targetLength,
    required TrussCatalog catalog,
  }) {
    if (targetLength.isZero) {
      return EdgeSolution(
        edgeId: edgeId,
        targetLength: targetLength,
        exactFit: true,
        pieces: const [],
      );
    }

    final allowedPieces = catalog.pieceTypes;
    if (allowedPieces.isEmpty) {
      return EdgeSolution(
        edgeId: edgeId,
        targetLength: targetLength,
        exactFit: false,
        pieces: const [],
      );
    }

    final targetTicks = targetLength.ticks;

    // Find max piece size in ticks to bound nearest higher search safely
    var maxPieceTicks = 0;
    for (final p in allowedPieces) {
      if (p.length.ticks > maxPieceTicks) {
        maxPieceTicks = p.length.ticks;
      }
    }

    // Upper bound for nearest higher search: target + maxPieceTicks
    final maxSearchTicks = targetTicks + maxPieceTicks;
    final dp = List<_DPState?>.filled(maxSearchTicks + 1, null);
    dp[0] = const _DPState(pieceCount: 0, pieceTicksDescending: []);

    // Build DP table from 1 to maxSearchTicks
    for (var len = 1; len <= maxSearchTicks; len++) {
      _DPState? bestForLen;

      for (final piece in allowedPieces) {
        final pTicks = piece.length.ticks;
        if (pTicks <= len) {
          final prevState = dp[len - pTicks];
          if (prevState != null) {
            final newPieces = List<int>.from(prevState.pieceTicksDescending)
              ..add(pTicks);
            newPieces.sort(
              (a, b) => b.compareTo(a),
            ); // Maintain descending order

            final candidate = _DPState(
              pieceCount: prevState.pieceCount + 1,
              pieceTicksDescending: newPieces,
            );

            if (bestForLen == null || candidate.compareTo(bestForLen) < 0) {
              bestForLen = candidate;
            }
          }
        }
      }

      dp[len] = bestForLen;
    }

    final targetState = dp[targetTicks];

    if (targetState != null) {
      // Exact fit found! Convert tick list to TrussPieceType objects
      final pieceList = _convertTicksToPieceTypes(
        targetState.pieceTicksDescending,
        catalog,
      );
      return EdgeSolution(
        edgeId: edgeId,
        targetLength: targetLength,
        exactFit: true,
        pieces: pieceList,
      );
    }

    // Exact fit impossible: find nearest lower and nearest higher feasible lengths
    Length? nearestLower;
    for (var len = targetTicks - 1; len > 0; len--) {
      if (dp[len] != null) {
        nearestLower = Length.fromTicks(len);
        break;
      }
    }

    Length? nearestHigher;
    for (var len = targetTicks + 1; len <= maxSearchTicks; len++) {
      if (dp[len] != null) {
        nearestHigher = Length.fromTicks(len);
        break;
      }
    }

    return EdgeSolution(
      edgeId: edgeId,
      targetLength: targetLength,
      exactFit: false,
      pieces: const [],
      nearestLower: nearestLower,
      nearestHigher: nearestHigher,
    );
  }

  static List<TrussPieceType> _convertTicksToPieceTypes(
    List<int> tickSequence,
    TrussCatalog catalog,
  ) {
    final result = <TrussPieceType>[];
    for (final ticks in tickSequence) {
      final len = Length.fromTicks(ticks);
      final pieceType = catalog.getPieceByLength(len);
      if (pieceType != null) {
        result.add(pieceType);
      } else {
        // Fallback piece specification if not explicitly named
        result.add(TrussPieceType(id: '${len.feet}ft', length: len));
      }
    }
    return result;
  }
}
