/// Pure domain rule for checking structural spans against span thresholds.
class TrussSpanRule {
  static const double maxStandardSpanFeet = 60.0;

  const TrussSpanRule();

  /// Returns true if the span exceeds the standard 60 ft threshold without
  /// an intermediate pillar/support.
  static bool exceedsSpanThreshold(double spanInFeet) {
    return spanInFeet > maxStandardSpanFeet;
  }

  /// Warning message for spans exceeding 60 ft.
  static String? getSpanWarning(double spanInFeet) {
    if (exceedsSpanThreshold(spanInFeet)) {
      return 'Span (${spanInFeet.round()} ft) exceeds standard 60 ft threshold. '
          'A vertical support pillar is recommended.';
    }
    return null;
  }
}
