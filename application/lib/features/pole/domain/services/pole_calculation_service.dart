import '../models/pole_calculation_input.dart';
import '../models/pole_calculation_result.dart';
import '../models/pole_grid.dart';
import '../models/pole_layout_point.dart';

class PoleCalculationService {
  const PoleCalculationService();

  PoleCalculationResult calculate(PoleCalculationInput input) {
    if (!input.isValid) {
      throw ArgumentError('Invalid plot dimensions. Length and width must be finite, positive numbers.');
    }

    final double l = input.plotLength;
    final double w = input.plotWidth;
    final double poleSize = input.poleSize;

    final int nLength = (l / poleSize).ceil();
    final int nWidth = (w / poleSize).ceil();

    final int verticalPoles = (nLength + 1) * (nWidth + 1);
    final int horizontalPipes = 2 * nLength * nWidth + nLength + nWidth;
    final int ceilingSections = nLength * nWidth;

    final int polesAlongLength = nLength + 1;
    final int polesAlongWidth = nWidth + 1;

    final List<PoleLayoutPoint> layoutPoints = [];

    for (int i = 0; i <= nWidth; i++) {
      for (int j = 0; j <= nLength; j++) {
        // Calculate X (along width) and Z (along length)
        double px = (i * poleSize).clamp(0.0, w);
        double pz = (j * poleSize).clamp(0.0, l);

        PoleClassification classification;
        bool isCornerX = i == 0 || i == nWidth;
        bool isCornerZ = j == 0 || j == nLength;

        if (isCornerX && isCornerZ) {
          classification = PoleClassification.corner;
        } else if (isCornerX || isCornerZ) {
          classification = PoleClassification.perimeter;
        } else {
          classification = PoleClassification.interior;
        }

        layoutPoints.add(PoleLayoutPoint(
          x: px,
          z: pz,
          classification: classification,
        ));
      }
    }

    return PoleCalculationResult(
      plotLength: l,
      plotWidth: w,
      poleSize: poleSize,
      grid: PoleGrid(
        bayUnit: poleSize,
        lengthBays: nLength,
        widthBays: nWidth,
      ),
      polesAlongLength: polesAlongLength,
      polesAlongWidth: polesAlongWidth,
      totalVerticalPoles: verticalPoles,
      totalHorizontalPipes: horizontalPipes,
      totalCeilingSections: ceilingSections,
      poleLayoutPoints: List.unmodifiable(layoutPoints),
    );
  }
}
