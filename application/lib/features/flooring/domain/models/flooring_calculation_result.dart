import 'flooring_carpet.dart';

class FlooringCalculationResult {
  // Echoed user inputs
  final double plotLength;
  final double plotWidth;
  final double carpetLength;
  final double carpetWidth;

  // Chosen orientation dimensions along plot axes
  final double orientedCarpetLength; // dimension along plot length (X axis)
  final double orientedCarpetWidth;  // dimension along plot width (Z axis)

  // Grid counts
  final int carpetsAlongLength;
  final int carpetsAlongWidth;
  final int totalCarpets;

  // Areas
  final double plotArea;
  final double carpetArea;

  // Actual physical coverage (may exceed plot dimensions due to ceil)
  final double coveredLength;
  final double coveredWidth;
  final double coveredArea;

  // Wastage / extra coverage
  final double extraCoverage;
  final double extraCoveragePercent;

  // Individual carpet objects in world-space
  final List<FlooringCarpet> carpetLayout;

  const FlooringCalculationResult({
    required this.plotLength,
    required this.plotWidth,
    required this.carpetLength,
    required this.carpetWidth,
    required this.orientedCarpetLength,
    required this.orientedCarpetWidth,
    required this.carpetsAlongLength,
    required this.carpetsAlongWidth,
    required this.totalCarpets,
    required this.plotArea,
    required this.carpetArea,
    required this.coveredLength,
    required this.coveredWidth,
    required this.coveredArea,
    required this.extraCoverage,
    required this.extraCoveragePercent,
    required this.carpetLayout,
  });
}
