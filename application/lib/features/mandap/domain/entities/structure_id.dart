import 'package:meta/meta.dart';

/// Strongly-typed identifier for a structural component / subgraph (e.g. 'main', 'entrance_1').
@immutable
class StructureId {
  final String value;

  const StructureId(this.value);

  static const StructureId main = StructureId('main');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StructureId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
