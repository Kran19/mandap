import 'package:meta/meta.dart';

/// BOM classification category for a structural truss member.
enum TrussMemberCategory {
  /// Vertical tower/pillar member extending from ground upward.
  pillar,

  /// Elevated perimeter, roof, cross, internal, or sloped apex member.
  upper,
}

/// Detailed BOM record for an individual structural member.
@immutable
class TrussMemberBomItem {
  final String edgeId;
  final TrussMemberCategory category;
  final double lengthFeet;

  const TrussMemberBomItem({
    required this.edgeId,
    required this.category,
    required this.lengthFeet,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrussMemberBomItem &&
          edgeId == other.edgeId &&
          category == other.category &&
          (lengthFeet - other.lengthFeet).abs() < 1e-4);

  @override
  int get hashCode => Object.hash(edgeId, category, (lengthFeet * 100).round());

  @override
  String toString() =>
      'TrussMemberBomItem($edgeId, ${category.name}, ${lengthFeet.toStringAsFixed(1)} ft)';
}

/// Authoritative summary of the Truss Bill of Materials separating Pillar and Upper truss.
@immutable
class TrussBomSummary {
  /// Number of actual structural pillar/vertical tower members.
  final int pillarQuantity;

  /// Total linear feet of pillar/vertical truss members.
  final double pillarTotalFeet;

  /// Number of actual structural upper/horizontal/roof truss members.
  final int upperQuantity;

  /// Total linear feet of upper/horizontal/roof truss members.
  final double upperTotalFeet;

  /// Combined total quantity: pillarQuantity + upperQuantity.
  final int totalQuantity;

  /// Combined total feet: pillarTotalFeet + upperTotalFeet.
  final double totalFeet;

  /// Detailed individual member list for pillars.
  final List<TrussMemberBomItem> pillarMembers;

  /// Detailed individual member list for upper/roof members.
  final List<TrussMemberBomItem> upperMembers;

  const TrussBomSummary({
    required this.pillarQuantity,
    required this.pillarTotalFeet,
    required this.upperQuantity,
    required this.upperTotalFeet,
    required this.totalQuantity,
    required this.totalFeet,
    this.pillarMembers = const [],
    this.upperMembers = const [],
  });

  /// Empty initial summary.
  static const empty = TrussBomSummary(
    pillarQuantity: 0,
    pillarTotalFeet: 0.0,
    upperQuantity: 0,
    upperTotalFeet: 0.0,
    totalQuantity: 0,
    totalFeet: 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrussBomSummary &&
          pillarQuantity == other.pillarQuantity &&
          (pillarTotalFeet - other.pillarTotalFeet).abs() < 1e-3 &&
          upperQuantity == other.upperQuantity &&
          (upperTotalFeet - other.upperTotalFeet).abs() < 1e-3 &&
          totalQuantity == other.totalQuantity &&
          (totalFeet - other.totalFeet).abs() < 1e-3 &&
          pillarMembers.length == other.pillarMembers.length &&
          upperMembers.length == other.upperMembers.length);

  @override
  int get hashCode => Object.hash(
        pillarQuantity,
        (pillarTotalFeet * 100).round(),
        upperQuantity,
        (upperTotalFeet * 100).round(),
        totalQuantity,
        (totalFeet * 100).round(),
      );

  @override
  String toString() =>
      'TrussBomSummary(Pillar: $pillarQuantity ($pillarTotalFeet ft), '
      'Upper: $upperQuantity ($upperTotalFeet ft), '
      'Total: $totalQuantity ($totalFeet ft))';
}
