import 'package:meta/meta.dart';

/// Strongly-typed identifier for a [MandapEdge].
@immutable
class EdgeId implements Comparable<EdgeId> {
  final String value;

  const EdgeId(this.value)
    : assert(value.length > 0, 'EdgeId value cannot be empty');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EdgeId && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(EdgeId other) => value.compareTo(other.value);

  @override
  String toString() => 'EdgeId($value)';
}
