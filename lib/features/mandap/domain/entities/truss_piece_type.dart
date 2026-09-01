import 'package:meta/meta.dart';
import '../../../../core/geometry/length.dart';

/// Represents a specific stock truss piece specification in the catalog.
@immutable
class TrussPieceType implements Comparable<TrussPieceType> {
  final String id;
  final Length length;
  final String name;

  const TrussPieceType({required this.id, required this.length, String? name})
    : name = name ?? '$length Truss';

  @override
  int compareTo(TrussPieceType other) => length.compareTo(other.length);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrussPieceType && id == other.id && length == other.length);

  @override
  int get hashCode => Object.hash(id, length);

  @override
  String toString() => 'TrussPieceType($id: $length)';
}
