import 'package:meta/meta.dart';
import '../entities/truss_catalog.dart';
import '../entities/truss_piece_type.dart';

/// Stock inventory tracking available counts per [TrussPieceType].
@immutable
class TrussInventory {
  final Map<TrussPieceType, int> quantities;

  const TrussInventory(this.quantities);

  /// Creates a sample inventory populated with [defaultQty] for every item in [catalog].
  factory TrussInventory.sample(TrussCatalog catalog, {int defaultQty = 10}) {
    final map = <TrussPieceType, int>{};
    for (final piece in catalog.pieceTypes) {
      map[piece] = defaultQty;
    }
    return TrussInventory(Map.unmodifiable(map));
  }

  /// Gets available quantity for a specific piece type.
  int getAvailable(TrussPieceType piece) => quantities[piece] ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrussInventory && _mapsEqual(quantities, other.quantities));

  @override
  int get hashCode => Object.hashAll(quantities.entries);

  static bool _mapsEqual<K, V>(Map<K, V> m1, Map<K, V> m2) {
    if (m1.length != m2.length) return false;
    for (final k in m1.keys) {
      if (!m2.containsKey(k) || m1[k] != m2[k]) return false;
    }
    return true;
  }

  @override
  String toString() => 'TrussInventory(${quantities.length} types)';
}
