import 'package:meta/meta.dart';
import '../entities/truss_piece_type.dart';

/// Represents a stock shortage for a specific [TrussPieceType].
@immutable
class InventoryShortage {
  final TrussPieceType pieceType;
  final int requiredCount;
  final int availableCount;

  int get shortageCount => requiredCount - availableCount;

  const InventoryShortage({
    required this.pieceType,
    required this.requiredCount,
    required this.availableCount,
  }) : assert(
         requiredCount > availableCount,
         'Shortage requires required > available',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryShortage &&
          pieceType == other.pieceType &&
          requiredCount == other.requiredCount &&
          availableCount == other.availableCount);

  @override
  int get hashCode => Object.hash(pieceType, requiredCount, availableCount);

  @override
  String toString() =>
      'InventoryShortage(${pieceType.name}: Required $requiredCount, Available $availableCount, Shortage $shortageCount)';
}
