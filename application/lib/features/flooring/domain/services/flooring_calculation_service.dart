import 'dart:math' as math;
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

    final double cLong = math.max(cl, cw);
    final double cShort = math.min(cl, cw);

    final bool isSwapped = input.isRotated ?? false;

    // Default (Unswapped): Horizontal rolls (cLong along X, cShort along Z)
    // Swapped (After Swap): Vertical rolls (cShort along X, cLong along Z)
    final double orientedCarpetLength = isSwapped ? cShort : cLong;
    final double orientedCarpetWidth  = isSwapped ? cLong  : cShort;

    final int carpetsAlongLength = (pl / orientedCarpetLength).ceil();
    final int carpetsAlongWidth  = (pw / orientedCarpetWidth).ceil();
    final int totalCarpets       = carpetsAlongLength * carpetsAlongWidth;

    final double coveredLength = carpetsAlongLength * orientedCarpetLength;
    final double coveredWidth  = carpetsAlongWidth  * orientedCarpetWidth;

    final double plotArea     = pl * pw;
    final double carpetArea   = cl * cw;
    final double coveredArea  = coveredLength * coveredWidth;

    final double extraCoverage        = math.max(0.0, coveredArea - plotArea);
    final double extraCoveragePercent = plotArea > 0 ? (extraCoverage / plotArea) * 100.0 : 0.0;

    final List<FlooringCarpet> carpets = [];
    int id = 0;

    // Row-by-row from top to bottom (Row 0: 1, 2, 3... Row 1: 4, 5, 6...)
    for (int row = 0; row < carpetsAlongWidth; row++) {
      for (int col = 0; col < carpetsAlongLength; col++) {
        carpets.add(FlooringCarpet(
          id:        id++,
          x:         col * orientedCarpetLength,
          z:         row * orientedCarpetWidth,
          width:     orientedCarpetLength,
          depth:     orientedCarpetWidth,
          rotation:  orientedCarpetLength == cl ? 0.0 : 90.0,
        ));
      }
    }

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
