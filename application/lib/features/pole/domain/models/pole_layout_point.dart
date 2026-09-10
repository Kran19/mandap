enum PoleClassification { corner, perimeter, interior }

class PoleLayoutPoint {
  final double x;
  final double z;
  final PoleClassification classification;

  const PoleLayoutPoint({
    required this.x,
    required this.z,
    required this.classification,
  });
}
