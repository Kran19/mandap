import 'pole_grid.dart';
import 'pole_layout_point.dart';

class PoleCalculationResult {
  final double plotLength;
  final double plotWidth;
  final double poleSize;
  final PoleGrid grid;
  final int polesAlongLength;
  final int polesAlongWidth;
  final int totalVerticalPoles;
  final int totalHorizontalPipes;
  final int totalCeilingSections;
  final List<PoleLayoutPoint> poleLayoutPoints;

  const PoleCalculationResult({
    required this.plotLength,
    required this.plotWidth,
    required this.poleSize,
    required this.grid,
    required this.polesAlongLength,
    required this.polesAlongWidth,
    required this.totalVerticalPoles,
    required this.totalHorizontalPipes,
    required this.totalCeilingSections,
    required this.poleLayoutPoints,
  });
}
