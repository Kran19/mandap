/// Model representing a single span segment between two structural support points.
class TrussSpanSegment {
  final double start;
  final double end;
  final double length;

  const TrussSpanSegment({
    required this.start,
    required this.end,
    required this.length,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrussSpanSegment &&
          runtimeType == other.runtimeType &&
          (start - other.start).abs() < 1e-4 &&
          (end - other.end).abs() < 1e-4 &&
          (length - other.length).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(start.round(), end.round(), length.round());

  @override
  String toString() => 'TrussSpanSegment(start: $start, end: $end, length: $length)';
}

/// Pure deterministic calculation service for 30-ft pillar spacing and segment marking.
///
/// Invariants:
/// - Support positions are generated at fixed 30-ft intervals: 0, 30, 60, ..., fullSegments * 30.
/// - If total length has a remainder, the final support is placed exactly at totalLength.
/// - The final remainder segment uses the exact remaining distance (not rounded up or down).
/// - No duplicate endpoints if remainder is zero.
/// - Rejects invalid inputs (<= 0, NaN, Infinity).
class TrussSupportSpacingCalculator {
  static const double defaultSpacing = 30.0;
  static const double epsilon = 0.05;

  const TrussSupportSpacingCalculator();

  /// Calculates deterministic support positions along a continuous run of [totalLength].
  ///
  /// Examples:
  /// - 100 ft -> [0.0, 30.0, 60.0, 90.0, 100.0]
  /// - 90 ft  -> [0.0, 30.0, 60.0, 90.0]
  /// - 80 ft  -> [0.0, 30.0, 60.0, 80.0]
  /// - 75 ft  -> [0.0, 30.0, 60.0, 75.0]
  /// - 60 ft  -> [0.0, 30.0, 60.0]
  /// - 45 ft  -> [0.0, 30.0, 45.0]
  /// - 30 ft  -> [0.0, 30.0]
  /// - 20 ft  -> [0.0, 20.0]
  ///
  /// Throws [ArgumentError] if [totalLength] or [interval] is not positive and finite.
  List<double> calculateSupportPositions(
    double totalLength, {
    double interval = defaultSpacing,
  }) {
    if (!totalLength.isFinite || totalLength <= 0.0) {
      throw ArgumentError('totalLength must be a positive finite number: $totalLength');
    }
    if (!interval.isFinite || interval <= 0.0) {
      throw ArgumentError('interval must be a positive finite number: $interval');
    }

    final positions = <double>[0.0];
    var current = interval;

    while (current < totalLength - epsilon) {
      positions.add(current);
      current += interval;
    }

    if ((totalLength - positions.last).abs() > epsilon) {
      positions.add(totalLength);
    } else {
      // Normalize floating point precision at endpoint
      positions[positions.length - 1] = totalLength;
    }

    return List.unmodifiable(positions);
  }

  /// Calculates contiguous span segments along [totalLength].
  ///
  /// For 100 ft:
  /// - Segment 1: start = 0, end = 30, length = 30
  /// - Segment 2: start = 30, end = 60, length = 30
  /// - Segment 3: start = 60, end = 90, length = 30
  /// - Segment 4: start = 90, end = 100, length = 10
  List<TrussSpanSegment> calculateSegments(
    double totalLength, {
    double interval = defaultSpacing,
  }) {
    final positions = calculateSupportPositions(totalLength, interval: interval);
    final segments = <TrussSpanSegment>[];

    for (int i = 0; i < positions.length - 1; i++) {
      final start = positions[i];
      final end = positions[i + 1];
      segments.add(
        TrussSpanSegment(
          start: start,
          end: end,
          length: end - start,
        ),
      );
    }

    return List.unmodifiable(segments);
  }
}
