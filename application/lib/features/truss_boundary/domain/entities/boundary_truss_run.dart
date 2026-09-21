/// Represents a continuous geometric span between two nodes/poles.
///
/// This entity owns its geometric definition, but does NOT own the material
/// breakdown (which is resolved dynamically by TrussMaterialService).
class BoundaryTrussRun {
  final String id;
  final String startNodeId;
  final String endNodeId;
  final String sideId;
  
  /// The physical geometric length of this span.
  final double geometricSpan;

  const BoundaryTrussRun({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
    required this.sideId,
    required this.geometricSpan,
  });

  BoundaryTrussRun copyWith({
    String? id,
    String? startNodeId,
    String? endNodeId,
    String? sideId,
    double? geometricSpan,
  }) {
    return BoundaryTrussRun(
      id: id ?? this.id,
      startNodeId: startNodeId ?? this.startNodeId,
      endNodeId: endNodeId ?? this.endNodeId,
      sideId: sideId ?? this.sideId,
      geometricSpan: geometricSpan ?? this.geometricSpan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startNodeId': startNodeId,
    'endNodeId': endNodeId,
    'sideId': sideId,
    'geometricSpan': geometricSpan,
  };

  factory BoundaryTrussRun.fromJson(Map<String, dynamic> json) {
    return BoundaryTrussRun(
      id: json['id'] as String,
      startNodeId: json['startNodeId'] as String,
      endNodeId: json['endNodeId'] as String,
      sideId: json['sideId'] as String,
      geometricSpan: (json['geometricSpan'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundaryTrussRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startNodeId == other.startNodeId &&
          endNodeId == other.endNodeId &&
          sideId == other.sideId &&
          (geometricSpan - other.geometricSpan).abs() < 0.001;

  @override
  int get hashCode => Object.hash(id, startNodeId, endNodeId, sideId, geometricSpan.round());

  @override
  String toString() =>
      'BoundaryTrussRun(id: $id, span: $geometricSpan ft, start: $startNodeId, end: $endNodeId)';
}
