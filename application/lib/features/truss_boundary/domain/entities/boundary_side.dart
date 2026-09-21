import 'boundary_truss_run.dart';

/// Represents one of the four boundary sides.
class BoundarySide {
  final String id;
  final List<BoundaryTrussRun> runs;

  const BoundarySide({
    required this.id,
    required this.runs,
  });

  double get totalLength => runs.fold(0.0, (sum, s) => sum + s.geometricSpan);

  BoundarySide copy() {
    return BoundarySide(
      id: id,
      runs: runs.map((r) => r.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'runs': runs.map((r) => r.toJson()).toList(),
  };

  factory BoundarySide.fromJson(Map<String, dynamic> json) {
    return BoundarySide(
      id: json['id'] as String,
      runs: (json['runs'] as List<dynamic>?)
              ?.map((e) => BoundaryTrussRun.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  String toString() =>
      'BoundarySide(id: $id, totalLength: $totalLength, runs: ${runs.length})';
}
