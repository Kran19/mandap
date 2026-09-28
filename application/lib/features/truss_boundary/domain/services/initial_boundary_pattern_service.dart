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
    final List<double> spans;
    if (customSequence != null && customSequence.isNotEmpty) {
      spans = customSequence;
    } else {
      final initSpan = customSpan != null && customSpan > 0
          ? customSpan
          : size.spanInFeet;
      spans = computeOptimalSpans(totalLength, initSpan);
    }

    final runs = <BoundaryTrussRun>[];
    double currentPos = 0;
    int index = 0;

    for (final span in spans) {
      if (currentPos >= totalLength - 0.05) break;
      final effectiveSpan = (currentPos + span > totalLength)
          ? (totalLength - currentPos)
          : span;

      runs.add(
        BoundaryTrussRun(
          id: '${sideId}_run_$index',
          startNodeId: '${sideId}_node_$index',
          endNodeId: '${sideId}_node_${index + 1}',
          sideId: sideId,
          geometricSpan: effectiveSpan,
        ),
      );

      currentPos += effectiveSpan;
      index++;
    }

    return BoundarySide(id: sideId, runs: runs);
  }

  /// Computes authoritative section spans based on product specifications:
  /// - Default 30ft pattern for 100ft: [30.0, 30.0, 30.0, 10.0]
  /// - 40ft length: [40.0] (directly 40ft, NOT 30 + 10)
  /// - 50ft length: [40.0, 10.0]
  /// - 60ft length: [30.0, 30.0]
  /// - 70ft length: [30.0, 30.0, 10.0] (or [40.0, 30.0] if 40ft requested)
  /// - 80ft length: [30.0, 30.0, 20.0] (or [40.0, 40.0] if 40ft requested)
  static List<double> computeOptimalSpans(double totalLength, double initialSpan) {
    if (totalLength <= 0) return const [];

    final lenInt = totalLength.round();
    if ((totalLength - lenInt).abs() < 0.1) {
      if (lenInt == 30) return const [30.0];
      if (lenInt == 40) return const [40.0];
      if (lenInt == 50) return const [40.0, 10.0];
      if (lenInt == 60) return const [30.0, 30.0];
      if (lenInt == 70) {
        return (initialSpan == 40.0) ? const [40.0, 30.0] : const [30.0, 30.0, 10.0];
      }
      if (lenInt == 80) {
        return (initialSpan == 40.0) ? const [40.0, 40.0] : const [30.0, 30.0, 20.0];
      }
      if (lenInt == 90) return const [30.0, 30.0, 30.0];
      if (lenInt == 100) {
        return (initialSpan == 40.0) ? const [40.0, 40.0, 20.0] : const [30.0, 30.0, 30.0, 10.0];
      }
    }

    final step = (initialSpan == 40.0) ? 40.0 : 30.0;
    final spans = <double>[];
    double rem = totalLength;

    while (rem > 0.05) {
      if (rem <= step) {
        spans.add(double.parse(rem.toStringAsFixed(1)));
        break;
      }
      if ((rem - 40.0).abs() < 0.1) {
        spans.add(40.0);
        break;
      }
      spans.add(step);
      rem -= step;
    }
    return spans;
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
