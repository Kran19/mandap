import '../models/flooring_calculation_input.dart';
import '../models/flooring_calculation_result.dart';
import '../models/flooring_carpet.dart';

class FlooringCalculationService {
  const FlooringCalculationService();

  FlooringCalculationResult calculate(FlooringCalculationInput input) {
    if (!input.isValid) {
      throw ArgumentError(
        'Invalid flooring input: all dimensions must be positive finite numbers.',
      );
    }

    final double pl = input.plotLength;
    final double pw = input.plotWidth;
    final double cl = input.carpetLength;
    final double cw = input.carpetWidth;

    // --- Evaluate Orientation A (no rotation: cl along plot length, cw along plot width) ---
    final int aAlongLength = (pl / cl).ceil();
    final int aAlongWidth  = (pw / cw).ceil();
    final int aTotal       = aAlongLength * aAlongWidth;

    // --- Evaluate Orientation B (rotated 90°: cw along plot length, cl along plot width) ---
    final int bAlongLength = (pl / cw).ceil();
    final int bAlongWidth  = (pw / cl).ceil();
    final int bTotal       = bAlongLength * bAlongWidth;

    // --- Choose orientation with fewer carpets; Orientation A wins on tie ---
    final bool useB = bTotal < aTotal;

    final int   carpetsAlongLength   = useB ? bAlongLength : aAlongLength;
    final int   carpetsAlongWidth    = useB ? bAlongWidth  : aAlongWidth;
    final int   totalCarpets         = useB ? bTotal       : aTotal;
    final double orientedCarpetLength = useB ? cw           : cl; // along plot length (X)
    final double orientedCarpetWidth  = useB ? cl           : cw; // along plot width (Z)
    final double rotationAngle        = useB ? 90.0         : 0.0;

    final double coveredLength = carpetsAlongLength * orientedCarpetLength;
    final double coveredWidth  = carpetsAlongWidth  * orientedCarpetWidth;

    final double plotArea     = pl * pw;
    final double carpetArea   = cl * cw;
    final double coveredArea  = coveredLength * coveredWidth;

    final double extraCoverage        = coveredArea - plotArea;
    final double extraCoveragePercent = (extraCoverage / plotArea) * 100.0;

    // --- Generate individual carpet layout ---
    final List<FlooringCarpet> carpets = [];
    int id = 0;
    for (int row = 0; row < carpetsAlongWidth; row++) {
      for (int col = 0; col < carpetsAlongLength; col++) {
        carpets.add(FlooringCarpet(
          id:       id++,
          x:        col * orientedCarpetLength,
          z:        row * orientedCarpetWidth,
          width:    orientedCarpetLength,
          depth:    orientedCarpetWidth,
          rotation: rotationAngle,
        ));
      }
    }

    assert(carpets.length == totalCarpets,
        'Generated ${carpets.length} carpets but expected $totalCarpets');

    return FlooringCalculationResult(
      plotLength:           pl,
      plotWidth:            pw,
      carpetLength:         cl,
      carpetWidth:          cw,
      orientedCarpetLength: orientedCarpetLength,
      orientedCarpetWidth:  orientedCarpetWidth,
      carpetsAlongLength:   carpetsAlongLength,
      carpetsAlongWidth:    carpetsAlongWidth,
      totalCarpets:         totalCarpets,
      plotArea:             plotArea,
      carpetArea:           carpetArea,
      coveredLength:        coveredLength,
      coveredWidth:         coveredWidth,
      coveredArea:          coveredArea,
      extraCoverage:        extraCoverage,
      extraCoveragePercent: extraCoveragePercent,
      carpetLayout:         List.unmodifiable(carpets),
    );
  }
}
