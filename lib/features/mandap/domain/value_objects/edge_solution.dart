import 'package:meta/meta.dart';
import '../../../../core/geometry/length.dart';
import '../entities/edge_id.dart';
import '../entities/truss_piece_type.dart';

/// Solution produced by [TrussOptimizer] for a single edge.
@immutable
class EdgeSolution {
  final EdgeId edgeId;
  final Length targetLength;
  final bool exactFit;

  /// Ordered truss pieces covering the edge (sorted descending for deterministic display).
  final List<TrussPieceType> pieces;

  /// Total piece count.
  int get pieceCount => pieces.length;

  /// Total joints along this edge (piece count - 1, minimum 0).
  int get jointCount => pieceCount > 0 ? pieceCount - 1 : 0;

  /// Suggested nearest lower feasible length if exactFit is false.
  final Length? nearestLower;

  /// Suggested nearest higher feasible length if exactFit is false.
  final Length? nearestHigher;

  const EdgeSolution({
    required this.edgeId,
    required this.targetLength,
    required this.exactFit,
    required this.pieces,
    this.nearestLower,
    this.nearestHigher,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EdgeSolution &&
          edgeId == other.edgeId &&
          targetLength == other.targetLength &&
          exactFit == other.exactFit &&
          _listEquals(pieces, other.pieces) &&
          nearestLower == other.nearestLower &&
          nearestHigher == other.nearestHigher);

  @override
  int get hashCode => Object.hash(
    edgeId,
    targetLength,
    exactFit,
    Object.hashAll(pieces),
    nearestLower,
    nearestHigher,
  );

  static bool _listEquals<T>(List<T> l1, List<T> l2) {
    if (l1.length != l2.length) return false;
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    if (exactFit) {
      return 'EdgeSolution($edgeId, $targetLength: ${pieces.map((p) => p.length).join(" + ")})';
    } else {
      return 'EdgeSolution($edgeId, $targetLength EXACT FIT IMPOSSIBLE, lower: $nearestLower, higher: $nearestHigher)';
    }
  }
}
