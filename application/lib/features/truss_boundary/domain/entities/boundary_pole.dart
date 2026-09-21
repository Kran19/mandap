/// Represents a physical structural pole or connection joint on the boundary.
/// Positioned at (x, z) coordinates in plot space.
class BoundaryPole {
  final String id;
  final double x;
  final double z;
  final bool isCorner;
  final bool isSupportPole;
  final List<String> connectedSideIds;

  const BoundaryPole({
    required this.id,
    required this.x,
    required this.z,
    this.isCorner = false,
    this.isSupportPole = false,
    this.connectedSideIds = const [],
  });

  BoundaryPole copyWith({
    String? id,
    double? x,
    double? z,
    bool? isCorner,
    bool? isSupportPole,
    List<String>? connectedSideIds,
  }) {
    return BoundaryPole(
      id: id ?? this.id,
      x: x ?? this.x,
      z: z ?? this.z,
      isCorner: isCorner ?? this.isCorner,
      isSupportPole: isSupportPole ?? this.isSupportPole,
      connectedSideIds: connectedSideIds ?? this.connectedSideIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'z': z,
    'isCorner': isCorner,
    'isSupportPole': isSupportPole,
    'connectedSideIds': connectedSideIds,
  };

  factory BoundaryPole.fromJson(Map<String, dynamic> json) {
    return BoundaryPole(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      isCorner: json['isCorner'] as bool? ?? false,
      isSupportPole: json['isSupportPole'] as bool? ?? false,
      connectedSideIds: (json['connectedSideIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundaryPole &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isSupportPole == other.isSupportPole &&
          isCorner == other.isCorner &&
          (x - other.x).abs() < 0.001 &&
          (z - other.z).abs() < 0.001;

  @override
  int get hashCode => Object.hash(id, x.round(), z.round(), isCorner, isSupportPole);

  @override
  String toString() =>
      'BoundaryPole(id: $id, x: $x, z: $z, isCorner: $isCorner, isSupportPole: $isSupportPole)';
}
