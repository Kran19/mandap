import 'package:meta/meta.dart';
import '../entities/edge_id.dart';
import '../entities/truss_piece_type.dart';
import 'edge_solution.dart';
import 'inventory_shortage.dart';
import 'pole_placement.dart';

/// Complete, validated output result of the Mandap calculation engine.
@immutable
class MandapCalculationResult {
  final List<String> layoutIssues;
  final Map<EdgeId, EdgeSolution> edgeSolutions;
  final Map<TrussPieceType, int> requiredTrussBySize;
  final List<PolePlacement> poles;
  final List<InventoryShortage> inventoryShortages;
  final List<String> warnings;

  const MandapCalculationResult({
    required this.layoutIssues,
    required this.edgeSolutions,
    required this.requiredTrussBySize,
    required this.poles,
    required this.inventoryShortages,
    required this.warnings,
  });

  /// True if layout is structurally valid and all edges have exact truss fits.
  bool get isValid =>
      layoutIssues.isEmpty && edgeSolutions.values.every((s) => s.exactFit);

  /// Total corner poles.
  int get cornerPoleCount =>
      poles.where((p) => p.reason == PoleReason.corner).length;

  /// Total generated intermediate poles.
  int get generatedPoleCount =>
      poles.where((p) => p.reason == PoleReason.generatedMaxSpan).length;

  /// Total poles.
  int get totalPoleCount => poles.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MandapCalculationResult &&
          _listEquals(layoutIssues, other.layoutIssues) &&
          _mapsEqual(edgeSolutions, other.edgeSolutions) &&
          _mapsEqual(requiredTrussBySize, other.requiredTrussBySize) &&
          _listEquals(poles, other.poles) &&
          _listEquals(inventoryShortages, other.inventoryShortages) &&
          _listEquals(warnings, other.warnings));

  @override
  int get hashCode => Object.hash(
    Object.hashAll(layoutIssues),
    Object.hashAll(edgeSolutions.entries),
    Object.hashAll(requiredTrussBySize.entries),
    Object.hashAll(poles),
    Object.hashAll(inventoryShortages),
    Object.hashAll(warnings),
  );

  static bool _listEquals<T>(List<T> l1, List<T> l2) {
    if (l1.length != l2.length) return false;
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) return false;
    }
    return true;
  }

  static bool _mapsEqual<K, V>(Map<K, V> m1, Map<K, V> m2) {
    if (m1.length != m2.length) return false;
    for (final k in m1.keys) {
      if (!m2.containsKey(k) || m1[k] != m2[k]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'MandapCalculationResult(Valid: $isValid, Poles: $totalPoleCount, BOM items: ${requiredTrussBySize.length}, Shortages: ${inventoryShortages.length})';
}
