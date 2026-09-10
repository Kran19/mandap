/// A single physical stage table/panel in world-space coordinates.
/// x and z are the top-left corner of the table on the ground plane.
/// width is the dimension along the X axis (stage length direction).
/// depth is the dimension along the Z axis (stage width direction).
class StageTable {
  final int id;
  final double x;
  final double z;
  final double width;
  final double depth;

  const StageTable({
    required this.id,
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
  });
}
