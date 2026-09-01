import 'package:meta/meta.dart';
import '../../../../core/geometry/length.dart';
import 'truss_piece_type.dart';

/// Configurable catalog of allowed stock truss piece types.
@immutable
class TrussCatalog {
  final List<TrussPieceType> pieceTypes;

  const TrussCatalog._(this.pieceTypes);

  /// Creates a custom [TrussCatalog] from a list of piece types.
  factory TrussCatalog(List<TrussPieceType> types) {
    final sorted = List<TrussPieceType>.from(types)..sort();
    return TrussCatalog._(List.unmodifiable(sorted));
  }

  /// Sample catalog containing standard 1 ft to 20 ft integer truss piece sizes.
  factory TrussCatalog.sample1To20Ft() {
    final types = List<TrussPieceType>.generate(20, (index) {
      final ft = index + 1;
      return TrussPieceType(
        id: '${ft}ft',
        length: Length.fromFeet(ft.toDouble()),
      );
    });
    return TrussCatalog(types);
  }

  /// Returns piece type for a specific exact length, if exists in catalog.
  TrussPieceType? getPieceByLength(Length length) {
    for (final piece in pieceTypes) {
      if (piece.length == length) return piece;
    }
    return null;
  }

  /// Returns allowed lengths in ticks sorted ascending.
  List<int> get allowedTicks => pieceTypes.map((p) => p.length.ticks).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrussCatalog && _listEquals(pieceTypes, other.pieceTypes));

  @override
  int get hashCode => Object.hashAll(pieceTypes);

  static bool _listEquals<T>(List<T> l1, List<T> l2) {
    if (l1.length != l2.length) return false;
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'TrussCatalog(${pieceTypes.length} types)';
}
