import '../entities/boundary_truss_run.dart';
import '../entities/truss_size.dart';

/// Pure domain service for evaluating required support poles based on the
/// authoritative consecutive section support interval rule.
///
/// AUTHORITATIVE RULE:
/// 10 ft: after every 3 consecutive sections -> 1 support pole
/// 20 ft: after every 2 consecutive sections -> 1 support pole
/// 25 ft: after every 2 consecutive sections -> 1 support pole
/// 30 ft: after every 2 consecutive sections -> 1 support pole
/// 40 ft: after every 1 section              -> 1 support pole
/// 50 ft: after every 1 section              -> 1 support pole
/// Custom: evaluates each section independently by standard rule
///         (different sizes do NOT combine into each other's counter)
class TrussPoleRequirementService {
  const TrussPoleRequirementService();

  /// Returns the number of consecutive truss sections of [size] before a support pole is required.
  static int getSectionsBeforeSupportPole(TrussSize size) {
    switch (size) {
      case TrussSize.ten:
        return 3;
      case TrussSize.twenty:
      case TrussSize.twentyFive:
      case TrussSize.thirty:
        return 2;
      case TrussSize.forty:
      case TrussSize.fifty:
        return 1;
      case TrussSize.custom:
        return 1;
    }
  }

  /// Calculates required support poles for a sequential list of section lengths (in feet).
  ///
  /// Evaluates consecutive sections of the same standard size against its interval rule.
  /// When a section of a DIFFERENT size is encountered, the previous size's counter does
  /// NOT contribute to the new size (counters are size-independent and reset on size change).
  static int calculateFromSectionSequence(List<double> sectionLengths) {
    int totalSupports = 0;
    TrussSize? currentSize;
    int currentConsecutiveCount = 0;

    for (final length in sectionLengths) {
      if (length <= 0) continue;
      final size = TrussSize.fromLength(length);
      final ruleInterval = getSectionsBeforeSupportPole(size);

      if (currentSize == size) {
        currentConsecutiveCount++;
      } else {
        currentSize = size;
        currentConsecutiveCount = 1;
      }

      if (ruleInterval > 0 && currentConsecutiveCount >= ruleInterval) {
        totalSupports++;
        currentConsecutiveCount = 0; // Support placed, consecutive interval resets
      }
    }

    return totalSupports;
  }

  /// Calculates total required support poles by evaluating actual structural runs
  /// against the consecutive section support interval for [trussSize].
  static int calculateRequiredSupportPoles({
    required TrussSize trussSize,
    required List<BoundaryTrussRun> runs,
  }) {
    if (runs.isEmpty) return 0;

    if (trussSize == TrussSize.custom) {
      // In Custom mode, each run is an explicit structural section of its geometricSpan.
      final sectionLengths = runs.map((r) => r.geometricSpan).toList();
      return calculateFromSectionSequence(sectionLengths);
    }

    // In standard mode, decompose each geometric span into standard section lengths of [trussSize].
    final sectionLengths = <double>[];
    final standardSpan = trussSize.spanInFeet;

    for (final run in runs) {
      final span = run.geometricSpan;
      if (standardSpan > 0) {
        final count = (span / standardSpan).floor();
        for (int i = 0; i < count; i++) {
          sectionLengths.add(standardSpan);
        }
        final remainder = span - (count * standardSpan);
        if (remainder > 0.05) {
          sectionLengths.add(remainder);
        }
      } else {
        sectionLengths.add(span);
      }
    }

    return calculateFromSectionSequence(sectionLengths);
  }
}
