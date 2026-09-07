import 'dart:math' as math;
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
  final int _ticks;

  const Length._(this._ticks);

  static const Length zero = Length._(0);

  factory Length.fromTicks(int ticks) {
    if (ticks < 0) {
      throw ArgumentError.value(ticks, 'ticks', 'Length ticks cannot be negative');
    }
    return Length._(ticks);
  }

  factory Length.fromFeet(double feet) {
    if (feet.isNaN || feet.isInfinite) {
      throw ArgumentError.value(feet, 'feet', 'Length must be finite');
    }
    if (feet < 0) {
      throw ArgumentError.value(feet, 'feet', 'Length cannot be negative');
    }
    
    // Strict 0.5 increment verification (allowing small float errors)
    final double ticksDouble = feet * 2;
    final int roundedTicks = ticksDouble.round();
    
    if ((ticksDouble - roundedTicks).abs() > 1e-5) {
      throw ArgumentError.value(feet, 'feet', 'Length must be in exact 0.5 ft increments');
    }
    
    return Length._(roundedTicks);
  }

  int get ticks => _ticks;
  
  double get feet => _ticks / 2.0;

  bool get isZero => _ticks == 0;
  bool get isPositive => _ticks > 0;

  Length operator +(Length other) => Length._(_ticks + other._ticks);

  Length operator -(Length other) {
    if (_ticks < other._ticks) {
      throw ArgumentError('Subtraction results in negative length');
    }
    return Length._(_ticks - other._ticks);
  }

  @override
  int compareTo(Length other) => _ticks.compareTo(other._ticks);

  bool operator <(Length other) => _ticks < other._ticks;
  bool operator <=(Length other) => _ticks <= other._ticks;
  bool operator >(Length other) => _ticks > other._ticks;
  bool operator >=(Length other) => _ticks >= other._ticks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Length && _ticks == other._ticks);

  @override
  int get hashCode => _ticks.hashCode;

  @override
  String toString() {
    if (_ticks % 2 == 0) {
      return '${_ticks ~/ 2} ft';
    }
    return '${feet} ft';
  }
}
