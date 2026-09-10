/// A single physical carpet piece in world-space coordinates.
/// x and z represent the top-left corner of the carpet on the ground plane.
/// width is the dimension along the X axis (plot length direction).
/// depth is the dimension along the Z axis (plot width direction).
/// rotation is the angle in degrees (e.g. 0.0 for Orientation A, 90.0 for Orientation B).
class FlooringCarpet {
  final int id;
  final double x;
  final double z;
  final double width;
  final double depth;
  final double rotation;

  const FlooringCarpet({
    required this.id,
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
    this.rotation = 0.0,
  });
}
