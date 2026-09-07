import 'package:meta/meta.dart';

/// Strongly-typed identifier for a [MandapNode].
@immutable
class NodeId implements Comparable<NodeId> {
  final String value;

  const NodeId(this.value)
    : assert(value.length > 0, 'NodeId value cannot be empty');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NodeId && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(NodeId other) => value.compareTo(other.value);

  @override
  String toString() => 'NodeId($value)';
}
