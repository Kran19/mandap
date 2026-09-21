/// Explicit state for a center light point.
enum CenterLightState {
  inactive,
  active,
}

/// Represents an interactive interior center light point.
/// Completely independent of structural boundary poles.
class CenterLightPoint {
  final String id;
  final double x;
  final double z;
  final CenterLightState state;

  const CenterLightPoint({
    required this.id,
    required this.x,
    required this.z,
    this.state = CenterLightState.inactive,
  });

  CenterLightPoint copyWith({
    String? id,
    double? x,
    double? z,
    CenterLightState? state,
  }) {
    return CenterLightPoint(
      id: id ?? this.id,
      x: x ?? this.x,
      z: z ?? this.z,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'z': z,
    'state': state.name,
  };

  factory CenterLightPoint.fromJson(Map<String, dynamic> json) {
    final stateName = json['state'] as String? ?? 'inactive';
    final state = CenterLightState.values.firstWhere(
      (s) => s.name == stateName,
      orElse: () => CenterLightState.inactive,
    );
    return CenterLightPoint(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      state: state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CenterLightPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (x - other.x).abs() < 0.001 &&
          (z - other.z).abs() < 0.001 &&
          state == other.state;

  @override
  int get hashCode => Object.hash(id, x.round(), z.round(), state);

  @override
  String toString() => 'CenterLightPoint(id: $id, x: $x, z: $z, state: $state)';
}
