import 'truss_size.dart';

/// Represents a single resolved physical material requirement derived dynamically
/// from the geometric run by TrussMaterialService.
class TrussMaterialRequirement {
  final String id;
  final double requiredLength;
  final TrussSize? stockType; // Null if custom
  final bool isCustom;

  const TrussMaterialRequirement({
    required this.id,
    required this.requiredLength,
    required this.stockType,
    required this.isCustom,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'requiredLength': requiredLength,
    'stockType': stockType?.name,
    'isCustom': isCustom,
  };

  factory TrussMaterialRequirement.fromJson(Map<String, dynamic> json) {
    return TrussMaterialRequirement(
      id: json['id'] as String? ?? 'mat_${json['requiredLength']}',
      requiredLength: (json['requiredLength'] as num).toDouble(),
      stockType: json['stockType'] != null
          ? TrussSize.values.firstWhere((e) => e.name == json['stockType'], orElse: () => TrussSize.thirty)
          : null,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrussMaterialRequirement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (requiredLength - other.requiredLength).abs() < 0.001 &&
          stockType == other.stockType &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(id, requiredLength.round(), stockType, isCustom);

  @override
  String toString() =>
      'TrussMaterialRequirement($id: ${requiredLength}ft, stock: ${stockType?.label}, custom: $isCustom)';
}
