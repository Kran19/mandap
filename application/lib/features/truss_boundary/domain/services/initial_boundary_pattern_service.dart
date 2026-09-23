import '../entities/boundary_truss_run.dart';
import '../entities/boundary_side.dart';
import '../entities/truss_size.dart';

/// Pure calculation engine for generating the INITIAL geometric structure.
///
/// This service is ONLY used when generating the boundary for the very first time.
/// Once the geometry is created, the user owns it, and edits use TrussMaterialService
/// and Split/Merge commands rather than regeneration.
class InitialBoundaryPatternService {
  const InitialBoundaryPatternService();

  /// Generates the four independent sides for a plot of [width] x [depth].
  static Map<String, BoundarySide> generateSides({
    required TrussSize initialTrussSize,
    required double width,
    required double depth,
    double? customSpan,
    List<double>? customSequence,
  }) {
    return {
      'north': _generateSide('north', width, initialTrussSize, customSpan: customSpan, customSequence: customSequence),
      'east': _generateSide('east', depth, initialTrussSize, customSpan: customSpan, customSequence: customSequence),
      'south': _generateSide('south', width, initialTrussSize, customSpan: customSpan, customSequence: customSequence),
      'west': _generateSide('west', depth, initialTrussSize, customSpan: customSpan, customSequence: customSequence),
    };
  }

  /// Convenience alias for generateSides
  static Map<String, BoundarySide> generateFourSides({
    required double plotWidth,
    required double plotDepth,
    required TrussSize trussSize,
    double? customSpan,
    List<double>? customSequence,
  }) {
    return generateSides(
      initialTrussSize: trussSize,
      width: plotWidth,
      depth: plotDepth,
      customSpan: customSpan,
      customSequence: customSequence,
    );
  }

  static BoundarySide _generateSide(
    String sideId,
    double totalLength,
    TrussSize size, {
    double? customSpan,
    List<double>? customSequence,
  }) {
    final spanPattern = (customSequence != null && customSequence.isNotEmpty)
        ? customSequence
        : _getInitialSectionLengths(size, customSpan: customSpan);
    final runs = <BoundaryTrussRun>[];
    
    double currentPos = 0;
    int index = 0;
    
    while (currentPos < totalLength) {
      double span = spanPattern[index % spanPattern.length];
      if (currentPos + span > totalLength) {
        span = totalLength - currentPos;
      }
      
      runs.add(
        BoundaryTrussRun(
          id: '${sideId}_run_$index',
          startNodeId: '${sideId}_node_$index',
          endNodeId: '${sideId}_node_${index + 1}',
          sideId: sideId,
          geometricSpan: span,
        ),
      );
      
      currentPos += span;
      index++;
    }

    return BoundarySide(id: sideId, runs: runs);
  }

  /// Returns the approved cyclic initial pattern for a given [TrussSize] or [customSpan].
  static List<double> _getInitialSectionLengths(TrussSize size, {double? customSpan}) {
    if (customSpan != null && customSpan > 0) {
      return [customSpan];
    }

    switch (size) {
      case TrussSize.ten:
        return const [10.0];
      case TrussSize.twenty:
        return const [20.0];
      case TrussSize.twentyFive:
        return const [25.0];
      case TrussSize.thirty:
        return const [30.0];
      case TrussSize.forty:
        return const [40.0];
      case TrussSize.fifty:
        return const [50.0];
      case TrussSize.custom:
        return customSpan != null && customSpan > 0 ? [customSpan] : const [30.0];
    }
  }
}

enum BoundarySideEnum {
  north,
  east,
  south,
  west
}
