import 'package:meta/meta.dart';

/// Represents an exact, quantized length for business calculations in Mandap.
///
/// Fundamental unit: 1 tick = 0.5 feet.
/// - 0.5 ft = 1 tick
/// - 1.0 ft = 2 ticks
/// - 10.0 ft = 20 ticks
/// - 10.5 ft = 21 ticks
/// - 30.0 ft = 60 ticks
///
/// Business calculations use pure integer tick arithmetic to guarantee
/// floating-point immunity and complete determinism.
@immutable
class Length implements Comparable<Length> {
  /// The integer number of 0.5 ft ticks.
  final int ticks;

  /// Private constructor forcing usage of factory/named constructors.
  const Length._(this.ticks);

  /// Zero length constant.
  static const Length zero = Length._(0);

  /// Constructs a [Length] directly from integer ticks (1 tick = 0.5 ft).
  ///
  /// Throws [ArgumentError] if [ticks] is negative.
  factory Length.fromTicks(int ticks) {
    if (ticks < 0) {
      throw ArgumentError.value(
        ticks,
        'ticks',
        'Length ticks cannot be negative',
      );
    }
    return Length._(ticks);
  }

  /// Constructs a [Length] from a double value in feet.
  ///
  /// Validates that [feet] is a precise 0.5 ft increment.
  /// For example: 10.0, 10.5 are valid; 10.3 is invalid and throws [ArgumentError].
  factory Length.fromFeet(double feet) {
    if (feet.isNaN || feet.isInfinite) {
      throw ArgumentError.value(
        feet,
        'feet',
        'Length in feet must be a finite number',
      );
    }
    if (feet < 0) {
      throw ArgumentError.value(
        feet,
        'feet',
        'Length in feet cannot be negative',
      );
    }
    final double rawTicks = feet * 2;
    final int roundedTicks = rawTicks.round();
    // Verify exact 0.5 ft quantization tolerance (1e-6)
    if ((rawTicks - roundedTicks).abs() > 1e-6) {
      throw ArgumentError(
        'Length $feet ft is not a valid 0.5 ft increment. Input must be divisible by 0.5 ft.',
      );
    }
    return Length._(roundedTicks);
  }

  /// Returns length in feet as a double.
  double get feet => ticks * 0.5;

  /// Returns true if length is zero.
  bool get isZero => ticks == 0;

  /// Returns true if length is greater than zero.
  bool get isPositive => ticks > 0;

  /// Adds two lengths deterministically.
  Length operator +(Length other) => Length._(ticks + other.ticks);

  /// Subtracts [other] length from this length.
  ///
  /// Throws [ArgumentError] if result would be negative.
  Length operator -(Length other) {
    final result = ticks - other.ticks;
    if (result < 0) {
      throw ArgumentError(
        'Subtraction results in negative length ($ticks - ${other.ticks})',
      );
    }
    return Length._(result);
  }

  /// Compares this length with another length.
  @override
  int compareTo(Length other) => ticks.compareTo(other.ticks);

  bool operator <(Length other) => ticks < other.ticks;
  bool operator <=(Length other) => ticks <= other.ticks;
  bool operator >(Length other) => ticks > other.ticks;
  bool operator >=(Length other) => ticks >= other.ticks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Length && ticks == other.ticks);

  @override
  int get hashCode => ticks.hashCode;

  @override
  String toString() {
    if (ticks % 2 == 0) {
      return '${(ticks ~/ 2)} ft';
    } else {
      return '${(ticks / 2).toStringAsFixed(1)} ft';
    }
  }
}
